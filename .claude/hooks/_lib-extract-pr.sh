#!/bin/bash
# Shared PR-number extraction for the three merge-gate hooks:
#   - block-unreviewed-merge.sh
#   - require-design-review-for-ui.sh
#   - block-merge-on-red-ci.sh
#
# Not a hook itself (prefixed with `_lib-` so it's never wired as one). Sourced
# by the hooks above via `. "$(dirname "$0")/_lib-extract-pr.sh"`.
#
# WHY THIS EXISTS
# ---------------
# The merge gates originally only matched `gh pr merge <N>`. Incident (#47):
# merges via `gh api repos/<owner>/<repo>/pulls/<N>/merge -X PUT` silently
# bypassed all three gates because neither the matcher nor the PR-number
# extraction knew about the API shape. This helper gives every gate a single,
# tested way to recognise both shapes:
#
#   1. `gh pr merge 42 --squash`                                  → PR is 42
#   2. `gh api repos/owner/repo/pulls/42/merge -X PUT`            → PR is 42
#
# Any tool that edits one of the three merge hooks MUST keep calling this
# helper, not re-implement the parsing inline. That's the whole point.
#
# USAGE
# -----
#   . "$(dirname "$0")/_lib-extract-pr.sh"
#   if ! is_merge_command "$COMMAND"; then exit 0; fi
#   PR_NUMBER=$(extract_pr_number "$COMMAND")

# Returns 0 if $1 looks like a merge command this gate should fire on.
# Matches EITHER:
#   - `gh pr merge ...`
#   - `gh api ... repos/<owner>/<repo>/pulls/<N>/merge ...`
is_merge_command() {
  local cmd="$1"
  if echo "$cmd" | grep -qE '\bgh\s+pr\s+merge\b'; then
    return 0
  fi
  # `gh api` with a `/pulls/<N>/merge` path anywhere in the command. The path
  # may be quoted, slash-separated, and may include query params.
  if echo "$cmd" | grep -qE '\bgh\s+api\b.*repos/[^/[:space:]]+/[^/[:space:]]+/pulls/[0-9]+/merge\b'; then
    return 0
  fi
  return 1
}

# Echoes the PR number extracted from the command, or empty if none found.
# Tries (in order):
#   1. `gh api .../pulls/<N>/merge` URL path
#   2. `gh pr merge <N>` first numeric arg
#   3. falls back to `gh pr view --json number` (current branch's PR)
extract_pr_number() {
  local cmd="$1"
  local pr=""

  # 1. gh api path extraction — greps the /pulls/<N>/merge segment directly.
  pr=$(echo "$cmd" | grep -oE 'repos/[^/[:space:]]+/[^/[:space:]]+/pulls/[0-9]+/merge' | grep -oE '/pulls/[0-9]+/' | grep -oE '[0-9]+' | head -1)

  # 2. gh pr merge positional arg — first bare number after `gh pr merge`,
  #    ignoring anything on the right side of a pipe / && / ; to avoid picking
  #    up a number from a follow-up command.
  if [ -z "$pr" ]; then
    pr=$(echo "$cmd" | grep -oE '\bgh\s+pr\s+merge\b[^|;&]*' | grep -oE '[0-9]+' | head -1)
  fi

  # 3. Last resort: ask gh which PR the current branch points at.
  if [ -z "$pr" ]; then
    pr=$(gh pr view --json number --jq '.number' 2>/dev/null)
  fi

  echo "$pr"
}

# Echoes the PR's HEAD SHA as reported by GitHub, or empty on failure.
#
# Why this exists (see #55): merge-gate hooks previously compared approval
# markers against `git rev-parse HEAD` (local HEAD). But `gh pr merge <N>`
# merges the PR's branch on GitHub's side, which is almost never equal to
# the local HEAD (local is usually `main` or a different feature branch).
# That meant every merge required a `gh pr checkout <N> && gh pr merge <N>`
# dance. Tedious and error-prone.
#
# This helper asks GitHub directly for the PR's HEAD via `gh pr view`.
# Works for both the `gh pr merge` and `gh api .../pulls/<N>/merge` shapes.
#
# Usage:
#   PR_HEAD=$(resolve_pr_head "$PR_NUMBER" "$CMD_REPO")
#   # Compare PR_HEAD against marker SHAs instead of git rev-parse HEAD.
#
# Failure modes (returns empty, caller should fall back):
#   - Network error / rate limit / gh auth expired
#   - PR doesn't exist (wrong number, closed, or wrong repo)
#   - GitHub API transient failure
#
# On failure the caller should fall back to `git rev-parse HEAD` with a
# visible warning — better to block a valid merge that the user can retry
# than silently allow a merge on the wrong SHA.
resolve_pr_head() {
  local pr_number="$1"
  local cmd_repo="$2"
  local sha=""

  if [ -z "$pr_number" ]; then
    echo ""
    return
  fi

  if [ -n "$cmd_repo" ]; then
    sha=$(gh pr view "$pr_number" --repo "$cmd_repo" --json headRefOid --jq '.headRefOid' 2>/dev/null)
  else
    sha=$(gh pr view "$pr_number" --json headRefOid --jq '.headRefOid' 2>/dev/null)
  fi

  echo "$sha"
}

# Echoes the `owner/repo` the merge command targets, or empty on failure.
# Resolution order:
#   1. Explicit `--repo <owner/repo>` flag on the command
#   2. `repos/<owner>/<repo>/pulls/<N>/merge` URL path from the API shape
#   3. `gh repo view --json nameWithOwner` — uses cwd's origin remote
#
# Why this exists (#7): merge-gate hooks previously resolved the marker dir
# via `git rev-parse --show-toplevel`, which returns the cwd's git root —
# not the repo the merge targets when `--repo` is used. That meant every
# `gh pr merge <N> --repo <other>` required a `cd` to the right repo first.
# This helper pulls the repo directly from the merge command, so marker
# paths follow the target repo rather than the cwd.
#
# Usage:
#   CMD_REPO=$(resolve_merge_repo "$COMMAND")
resolve_merge_repo() {
  local cmd="$1"
  local repo=""

  # 1. Explicit --repo flag
  repo=$(echo "$cmd" | sed -nE 's/.*--repo[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)

  # 2. API shape: repos/<owner>/<repo>/pulls/<N>/merge
  if [ -z "$repo" ]; then
    repo=$(echo "$cmd" | grep -oE 'repos/[^/[:space:]]+/[^/[:space:]]+/pulls/[0-9]+/merge' | sed -nE 's|repos/([^/]+/[^/]+)/pulls/.*|\1|p' | head -1)
  fi

  # 3. Ask gh for the cwd's default repo
  if [ -z "$repo" ]; then
    repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  fi

  echo "$repo"
}

# Walks up from cwd until it finds a directory containing `onboarding.yaml`.
# That's the ApexYard ops-fork root — where `.claude/hooks/`, `.claude/rules/`,
# `.claude/session/reviews/`, etc. live. Returns empty if no onboarding.yaml
# is found up to `/`.
#
# Why this exists (#7): marker files must live in a single canonical
# location (the ops fork) so merges from any cwd — inside a managed repo's
# workspace/, inside the ops fork itself, or a nested subdirectory — resolve
# to the same `.claude/session/reviews/` tree. `git rev-parse --show-toplevel`
# returns the *cwd's* repo root, which in a multi-managed-project setup is
# usually wrong.
#
# Usage:
#   OPS_FORK=$(find_ops_fork_root)
find_ops_fork_root() {
  local r="$PWD"
  # Guard on [ -n "$r" ] to break out when r collapses to empty — which happens
  # one iteration after r="/" because bash's `${r%/*}` on "/" is "". Without this
  # guard the loop spins forever when onboarding.yaml isn't anywhere up the tree.
  while [ -n "$r" ] && [ ! -f "$r/onboarding.yaml" ] && [ "$r" != "/" ]; do
    r="${r%/*}"
  done
  if [ -n "$r" ] && [ -f "$r/onboarding.yaml" ]; then
    echo "$r"
  else
    echo ""
  fi
}

# Echoes the absolute marker-directory path for a given `owner/repo`, anchored
# at the ops-fork root. Creates a per-repo subdir so two managed repos that
# both have a PR #4 don't collide on a single `4-*.approved` filename.
#
# Why this exists (#7): before this helper, markers lived flat under
# `.claude/session/reviews/<N>-*.approved`, keyed only by PR number. Two
# managed repos with a PR of the same number shared files — surfaced in
# production on 2026-04-24 when `mrshousha/apexyard#4` (merged) left a stale
# CEO marker at `4-ceo.approved` that then collided with `mrshousha/ravely#4`.
#
# The new scheme: `.claude/session/reviews/<owner>/<repo>/<N>-*.approved`.
# Per-repo subdir, no collision, same number in different repos is fine.
#
# Usage:
#   REVIEWS_DIR=$(reviews_dir "$OWNER_REPO")    # e.g. "mrshousha/ravely"
#   # → /Users/.../apexyard/.claude/session/reviews/mrshousha/ravely
reviews_dir() {
  local owner_repo="$1"
  local ops_fork
  ops_fork=$(find_ops_fork_root)

  if [ -z "$ops_fork" ] || [ -z "$owner_repo" ]; then
    # Caller must fall back — no sane namespace available
    echo ""
    return
  fi

  echo "${ops_fork}/.claude/session/reviews/${owner_repo}"
}
