#!/bin/bash
# Shared cd-target detection for PreToolUse Bash hooks (apexyard#9).
#
# Not a hook itself (prefixed with `_lib-` so it's never wired as one). Sourced
# by hooks via `. "$(dirname "$0")/_lib-cd-target.sh"`.
#
# WHY THIS EXISTS
# ---------------
# When an agent runs `cd workspace/ravely && git push origin feature/X`, the
# Claude Code harness fires PreToolUse Bash hooks BEFORE the `cd` actually
# happens. The hooks therefore see `$PWD` set to the harness's CWD (typically
# the apexyard ops fork root), not to the cd target embedded in the command.
#
# Hooks that shell out to `git` for state — `git branch --show-current`,
# `git remote get-url origin`, `git rev-parse --show-toplevel` — pick up the
# ops fork's state instead of the managed project's state. Every check after
# that is wrong-context, and the hook either:
#
#   - blocks a perfectly valid push because the apexyard worktree happens to
#     have a non-conformant branch name (`worktree-agent-aXXXX`), OR
#   - resolves the tracker repo as `mrshousha/apexyard` and tells the agent
#     `Closes #42` is a fabricated reference — when in fact #42 is a real
#     issue in the managed project's tracker, NOT apexyard's.
#
# This helper extracts the `cd <path>` prefix from the matched command and
# chdir's the hook process into it before any git lookup. Falls back to the
# original `$PWD` when no `cd` prefix is present (the original behaviour for
# hooks invoked from inside a managed project's clone directly).
#
# USAGE
# -----
#   . "$(dirname "$0")/_lib-cd-target.sh"
#   COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
#   cd_to_command_target "$COMMAND"
#   # ...rest of hook now operates from the matched command's cd target
#
# Subshell guidance: hooks that fork sub-processes (sed, grep, jq) inherit
# the chdir, so a single `cd_to_command_target` call near the top is enough.
# If a hook needs to bounce back to the original directory after the chdir,
# capture `_ORIGINAL_PWD="$PWD"` before calling and `cd "$_ORIGINAL_PWD"` to
# restore. None of the current callers need that.

# Echoes the cd target extracted from a leading `cd <path> &&|;` prefix.
# Empty if the command doesn't start with a `cd <path>` prefix.
#
# Recognises the four common chaining shapes:
#   cd <path> && ...
#   cd <path>; ...
#   cd <path> || ...   (rare but valid)
#   cd <path>           (no chain, the whole command is just `cd`)
#
# Does NOT recognise:
#   - `pushd <path> && ...` (deliberately — different semantics; if an agent
#     uses pushd we want the hook to keep using $PWD rather than guess)
#   - `(cd <path> && ...)` subshells (the parenthesised form embeds the cd
#     so $PWD never changes from the harness's perspective; same wrong-context
#     symptom but a different fix surface — out of scope for the initial cut)
#   - `cd -` / `cd ~` / `cd $VAR` (no expansion is performed; if the path
#     isn't a literal we fall back to $PWD)
#
# Path is taken as the longest run of non-whitespace, non-`&`, non-`;`,
# non-`|` characters after `cd `. That covers absolute paths, relative paths,
# and paths with `/` segments. Quoted paths (`"path with spaces"`) are out of
# scope — agents don't use them in the failure mode this targets.
extract_cd_target() {
  local cmd="$1"
  echo "$cmd" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:]&;|]+)([[:space:]]+(&&|\|\|)|[[:space:]]*;|[[:space:]]*$).*/\1/p' | head -1
}

# Resolves the cd target to an absolute path. Relative targets are resolved
# against the current $PWD (the harness's CWD at hook-launch time). Absolute
# targets pass through unchanged.
#
# Returns empty if the input is empty or the resolved path doesn't exist as
# a directory — in either case the caller should stay in $PWD.
resolve_cd_target() {
  local target="$1"
  if [ -z "$target" ]; then
    echo ""
    return
  fi

  # Already absolute
  case "$target" in
    /*)
      [ -d "$target" ] && echo "$target" || echo ""
      return
      ;;
  esac

  # Relative — resolve against $PWD
  local resolved="$PWD/$target"
  if [ -d "$resolved" ]; then
    # Canonicalise via cd + pwd -P to collapse `..` and symlinks. Quietly
    # fall back to the un-canonicalised form if the cd fails (shouldn't
    # happen since we just checked -d, but defensive).
    (cd "$resolved" && pwd -P) 2>/dev/null || echo "$resolved"
  else
    echo ""
  fi
}

# Convenience: extract + resolve + chdir in one call. Silent no-op if the
# command has no cd prefix or the target doesn't resolve.
#
# After this returns, $PWD is either the cd target (success) or unchanged
# (no cd prefix, or target doesn't exist). Callers that want to detect
# which happened can compare $PWD before and after.
cd_to_command_target() {
  local cmd="$1"
  local target resolved
  target=$(extract_cd_target "$cmd")
  if [ -z "$target" ]; then
    return 0
  fi
  resolved=$(resolve_cd_target "$target")
  if [ -n "$resolved" ]; then
    cd "$resolved" 2>/dev/null || true
  fi
}
