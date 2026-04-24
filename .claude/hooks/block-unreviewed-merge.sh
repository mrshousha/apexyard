#!/bin/bash
# PreToolUse hook on `gh pr merge` AND `gh api .../pulls/<N>/merge`: blocks
# merging a PR that does not have BOTH required approval markers in place.
#
# Both merge shapes are covered — see _lib-extract-pr.sh for the parser and
# #47 for why the API-shape bypass was a gap worth closing.
#
# Enforces workflow-gates rule #5 ("2 reviews — agent + human, CI green,
# commit SHA matches review") at the merge boundary, mechanically. Two
# markers are required, anchored per-repo under the ops fork (see #7 for
# why per-repo namespacing replaced the old flat `<N>-*.approved` scheme):
#
#   <ops-fork>/.claude/session/reviews/<owner>/<repo>/<pr>-rex.approved
#     Written by the code-reviewer agent (Rex) after a successful review.
#     Contents: the commit SHA Rex reviewed.
#
#   <ops-fork>/.claude/session/reviews/<owner>/<repo>/<pr>-ceo.approved
#     Written ONLY by the /approve-merge <pr> skill on explicit user
#     invocation. Contents: the commit SHA the CEO approved.
#
# Both markers must exist, and both SHAs must match the live HEAD. Any
# commits pushed after approval invalidate both — re-review and re-approve.
#
# The CEO marker is the mechanical enforcement of the "plan-level 'go' is
# NOT merge approval" rule in .claude/rules/pr-workflow.md. An umbrella
# "go" on a plan does not produce this file — only the /approve-merge
# skill does, and the skill is defined to run only on explicit user
# invocation that names the PR.
#
# Claude can technically forge either marker by running `touch` or `echo`
# directly. Doing so is a visible, auditable, grep-able rule violation
# and is itself a hard stop. The point of mechanical enforcement is to
# turn invisible inference failures into visible rule violations.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Shared merge-shape detector + PR-number parser (see _lib-extract-pr.sh).
# Handles `gh pr merge <N>` and `gh api repos/<owner>/<repo>/pulls/<N>/merge`.
. "$(dirname "$0")/_lib-extract-pr.sh"

if ! is_merge_command "$COMMAND"; then
  exit 0
fi

# Resolve the target repo of the merge (from --repo, the API URL, or the
# cwd's origin). This is what the marker-path scheme keys on now, replacing
# the old cwd-dependent `git rev-parse --show-toplevel` lookup (see #7).
CMD_REPO=$(resolve_merge_repo "$COMMAND")

PR_NUMBER=$(extract_pr_number "$COMMAND")

if [ -z "$PR_NUMBER" ]; then
  echo "BLOCKED: Could not determine PR number for merge. Run from a PR branch or pass an explicit PR number." >&2
  exit 2
fi

if [ -z "$CMD_REPO" ]; then
  echo "BLOCKED: Could not determine target repo for merge. Pass --repo <owner/repo> or run inside a repo with a GitHub origin." >&2
  exit 2
fi

REVIEWS_DIR=$(reviews_dir "$CMD_REPO")
if [ -z "$REVIEWS_DIR" ]; then
  echo "BLOCKED: Could not locate ops-fork root (no onboarding.yaml found walking up from $PWD). This hook requires an ApexYard ops fork above the cwd." >&2
  exit 2
fi
REX_APPROVAL="${REVIEWS_DIR}/${PR_NUMBER}-rex.approved"
CEO_APPROVAL="${REVIEWS_DIR}/${PR_NUMBER}-ceo.approved"

# Resolve the PR's real HEAD via GitHub, not local git (see #55). The local
# HEAD is rarely the PR's HEAD — usually main or an unrelated feature
# branch. Asking gh directly removes the need for `gh pr checkout <N>`
# before every `gh pr merge <N>`.
#
# Fallback to local HEAD if the gh call fails, with a visible warning, so
# a transient network / auth issue doesn't brick merges entirely.
CURRENT_SHA=$(resolve_pr_head "$PR_NUMBER" "$CMD_REPO")
if [ -z "$CURRENT_SHA" ]; then
  echo "WARN: Could not resolve PR #${PR_NUMBER} HEAD via gh — falling back to local HEAD. If this merge fails, run 'gh pr checkout ${PR_NUMBER}' first or re-authenticate gh." >&2
  CURRENT_SHA=$(git rev-parse HEAD 2>/dev/null)
fi

# --- Rex marker check ---
if [ ! -f "$REX_APPROVAL" ]; then
  cat >&2 <<MSG
BLOCKED: PR #${PR_NUMBER} has no recorded code-reviewer (Rex) approval.

ApexYard requires two reviews before merge (workflow-gates rule #5):
  1. Code Reviewer agent (Rex) — automated, recorded in reviews/<owner>/<repo>/
  2. Human approver (CEO) — recorded by the /approve-merge skill

Missing file:
  ${REX_APPROVAL}

To unblock:
  1. Invoke the code-reviewer agent on this PR (it writes the marker to the
     per-repo path above — see .claude/agents/code-reviewer.md)
  2. Then run /approve-merge ${PR_NUMBER} for the CEO approval
  3. Retry the merge

Never skip this check — even for typo fixes. See .claude/rules/pr-workflow.md.
MSG
  exit 2
fi

REX_SHA=$(tr -d '[:space:]' < "$REX_APPROVAL")
if [ -n "$REX_SHA" ] && [ -n "$CURRENT_SHA" ] && [ "$REX_SHA" != "$CURRENT_SHA" ]; then
  cat >&2 <<MSG
BLOCKED: Code-reviewer approved commit ${REX_SHA:0:7} but HEAD is now ${CURRENT_SHA:0:7}.

New commits were pushed after the Rex review. Re-invoke Rex on the latest
HEAD before merging.
MSG
  exit 2
fi

# --- CEO marker check ---
if [ ! -f "$CEO_APPROVAL" ]; then
  cat >&2 <<MSG
BLOCKED: PR #${PR_NUMBER} has Rex approval but no CEO approval marker.

Plan-level "go" / "continue" / "ship it" does NOT authorize a merge. Each
merge requires an explicit per-PR, per-merge CEO approval that names the
PR. See .claude/rules/pr-workflow.md § "Plan-level 'go' is NOT merge
approval" for the full rationale.

Missing file:
  ${CEO_APPROVAL}

To unblock:
  1. Stop and ask the CEO explicitly: "PR #${PR_NUMBER} ready to merge — approved?"
  2. When the CEO says "approved" / "merge it" / "ship it" naming PR #${PR_NUMBER},
     invoke the /approve-merge skill:
       /approve-merge ${PR_NUMBER}
  3. The skill writes ${CEO_APPROVAL} with the current HEAD SHA
  4. Retry the merge

NEVER create this marker yourself from an umbrella "go" on a plan.
EVER. This is the exact failure this hook exists to prevent.
MSG
  exit 2
fi

CEO_SHA=$(tr -d '[:space:]' < "$CEO_APPROVAL")
if [ -n "$CEO_SHA" ] && [ -n "$CURRENT_SHA" ] && [ "$CEO_SHA" != "$CURRENT_SHA" ]; then
  cat >&2 <<MSG
BLOCKED: CEO approved commit ${CEO_SHA:0:7} but HEAD is now ${CURRENT_SHA:0:7}.

New commits were pushed after the CEO approval. Re-request CEO approval
via /approve-merge ${PR_NUMBER} on the new HEAD before merging.
MSG
  exit 2
fi

exit 0
