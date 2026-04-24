#!/bin/bash
# PostToolUse hook: after `gh pr create` succeeds, tell Claude to invoke the
# code-reviewer agent (Rex) on the new PR automatically.
#
# Mechanism: the hook writes a pending-review marker and exits with code 2
# so the stderr message is surfaced back to Claude as an "error", which in
# practice is how Claude Code's PostToolUse hooks push the next instruction
# into the conversation. Exit 2 does NOT roll back the PR — it just nudges
# Claude to run the review immediately rather than "later".
#
# Marker paths are per-repo to match the merge-gate hooks (#7):
#   <ops-fork>/.claude/session/pending-reviews/<owner>/<repo>/<pr>
#   <ops-fork>/.claude/session/reviews/<owner>/<repo>/<pr>-rex.approved

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
# The `gh` output may surface at .tool_response.stdout (newer harness,
# Claude Code 2.x+), .tool_response.output (older 1.x), or .tool_response as
# a plain string (earliest builds). Triple fallback covers harness drift across
# 2025-2026 releases — simplify to .stdout only once the older paths are gone.
OUTPUT=$(echo "$INPUT" | jq -r '.tool_response.stdout // .tool_response.output // .tool_response // empty' 2>/dev/null)

if [ "$TOOL_NAME" != "Bash" ] || [ -z "$COMMAND" ]; then
  exit 0
fi

# Only fire on gh pr create
if ! echo "$COMMAND" | grep -qE '\bgh\s+pr\s+create\b'; then
  exit 0
fi

# Source the shared lib for reviews_dir + find_ops_fork_root
. "$(dirname "$0")/_lib-extract-pr.sh"

# Extract the PR URL from the tool output (gh prints the URL on success).
# URL shape: https://github.com/<owner>/<repo>/pull/<N>
PR_URL=$(echo "$OUTPUT" | grep -oE 'https://github\.com/[^[:space:]]+/pull/[0-9]+' | head -1)
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
OWNER_REPO=$(echo "$PR_URL" | sed -nE 's|https://github\.com/([^/]+/[^/]+)/pull/[0-9]+|\1|p')

if [ -z "$PR_NUMBER" ]; then
  PR_REF="the PR you just created"
else
  PR_REF="PR #$PR_NUMBER"
fi

# Write the pending-review marker and compute the expected rex-approval path
# under the per-repo namespace (#7). If we can't resolve the ops-fork or
# owner/repo, fall back to a flat path so the hook still nudges Rex but the
# merge gate will later print a clearer error.
OPS_FORK=$(find_ops_fork_root)
REX_PATH_HINT=".claude/session/reviews/${OWNER_REPO:-<owner/repo>}/${PR_NUMBER:-<pr>}-rex.approved"
if [ -n "$OPS_FORK" ] && [ -n "$OWNER_REPO" ] && [ -n "$PR_NUMBER" ]; then
  PENDING_DIR="${OPS_FORK}/.claude/session/pending-reviews/${OWNER_REPO}"
  mkdir -p "$PENDING_DIR"
  echo "${PR_URL}" > "${PENDING_DIR}/${PR_NUMBER}"
  REX_PATH_HINT="${OPS_FORK}/.claude/session/reviews/${OWNER_REPO}/${PR_NUMBER}-rex.approved"
fi

cat >&2 <<MSG
AUTO CODE REVIEW REQUIRED

You just created ${PR_REF}. ApexYard requires the code-reviewer agent (Rex)
to run on every PR before it can be merged — see workflows/code-review.md
and .claude/rules/pr-workflow.md. Invoke Rex NOW using the Agent tool:

  subagent_type: code-reviewer
  prompt: "Review ${PR_REF} at ${PR_URL}. Check the diff, tests, coverage,
           AgDR linkage, glossary, and commit SHA consistency. Report verdict.
           Owner/repo: ${OWNER_REPO:-<owner/repo>}. Write the approval marker
           at ${REX_PATH_HINT}."

The merge-gate hook will block \`gh pr merge\` for this PR until a Rex approval
file exists at ${REX_PATH_HINT}.

This message is a reminder from the PostToolUse hook, not a tool error. The PR
was created successfully.
MSG
exit 2
