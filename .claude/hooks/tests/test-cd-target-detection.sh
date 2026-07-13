#!/bin/bash
# Tests for the cd-target detection fix (apexyard#9).
#
# Strategy: build a fake ops fork in a tempdir with a fake managed-project
# git repo inside `workspace/`. Drive each affected hook with synthetic JSON
# stdin shaped like the harness's PreToolUse payload, where the matched
# command begins with `cd <path> && ...`. Assert that the hook now reads
# state from the cd target (correct) instead of $PWD (wrong, the bug).
#
# Run from the repo root:
#   bash .claude/hooks/tests/test-cd-target-detection.sh
#
# Exit status:
#   0 — all assertions passed
#   1 — at least one assertion failed (details on stderr)

set -u

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_NAME=""
TESTS_RUN=0
TESTS_PASS=0
TESTS_FAIL=0
FAILURES=()

# --------- test harness helpers ---------

setup_fake_ops_fork() {
  local root="$1"
  mkdir -p "$root"
  touch "$root/onboarding.yaml"
  touch "$root/apexyard.projects.yaml"
  # Make the ops fork a git repo with a non-conformant branch (the failure
  # mode the bug surfaces — apexyard worktrees often live on agent-temp
  # branches like `worktree-agent-aXXXX`).
  (cd "$root" && git init -q -b worktree-agent-abc123 && \
    git config user.email "test@example.com" && \
    git config user.name "Test" && \
    git remote add origin git@github.com:fake-owner/apexyard.git && \
    echo "stub" > README.md && \
    git add README.md && \
    git commit -q -m "stub: initial")
}

setup_fake_managed_project() {
  local ops_root="$1"
  local name="$2"
  local branch="$3"
  local origin="$4"

  local proj="$ops_root/workspace/$name"
  mkdir -p "$proj"
  (cd "$proj" && git init -q -b "$branch" && \
    git config user.email "test@example.com" && \
    git config user.name "Test" && \
    git remote add origin "$origin" && \
    echo "stub" > README.md && \
    git add README.md && \
    git commit -q -m "stub: initial")
}

# Run a hook with a JSON payload on stdin from a given $PWD. Returns the
# hook's exit code; captures stderr in $LAST_STDERR.
run_hook() {
  local hook="$1"
  local payload="$2"
  local cwd="$3"
  LAST_STDERR=$(cd "$cwd" && echo "$payload" | "$HOOKS_DIR/$hook" 2>&1 >/dev/null)
  return $?
}

# Pretty-print a result. Args: name, expected_exit, actual_exit, msg.
assert_exit() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  local msg="${4:-}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$expected" = "$actual" ]; then
    TESTS_PASS=$((TESTS_PASS + 1))
    echo "  PASS  $name (exit=$actual)"
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    FAILURES+=("$name: expected exit=$expected, got exit=$actual${msg:+ — $msg}")
    echo "  FAIL  $name (expected exit=$expected, got exit=$actual)"
    [ -n "$LAST_STDERR" ] && echo "        stderr: $LAST_STDERR" | head -5
  fi
}

# --------- tests ---------

echo "=== _lib-cd-target.sh: extract_cd_target ==="
. "$HOOKS_DIR/_lib-cd-target.sh"

# Direct lib tests
test_extract() {
  local name="$1"
  local cmd="$2"
  local expected="$3"
  local actual
  actual=$(extract_cd_target "$cmd")
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$actual" = "$expected" ]; then
    TESTS_PASS=$((TESTS_PASS + 1))
    echo "  PASS  $name (got '$actual')"
  else
    TESTS_FAIL=$((TESTS_FAIL + 1))
    FAILURES+=("$name: expected '$expected', got '$actual'")
    echo "  FAIL  $name (expected '$expected', got '$actual')"
  fi
}

test_extract "absolute-path && chain"   "cd /tmp/foo && git push"           "/tmp/foo"
test_extract "relative-path && chain"   "cd workspace/ravely && git commit" "workspace/ravely"
test_extract "single-segment && chain"  "cd ravely && gh pr create"         "ravely"
test_extract "; chain"                  "cd /tmp/foo; git push"             "/tmp/foo"
test_extract "no cd prefix"             "git push origin main"              ""
test_extract "leading whitespace"       "  cd /tmp/foo && git push"         "/tmp/foo"
test_extract "cd alone"                 "cd /tmp/foo"                       "/tmp/foo"
test_extract "cd at end of subcommand"  "echo hi && cd /tmp/foo"            ""
test_extract "pushd not matched"        "pushd /tmp/foo && git push"        ""

echo ""
echo "=== validate-branch-name.sh: cd-target branch read ==="

OPS_ROOT_1="$(mktemp -d)/ops"
setup_fake_ops_fork "$OPS_ROOT_1"
setup_fake_managed_project "$OPS_ROOT_1" "ravely" "feature/#42-add-foo" \
  "git@github.com:fake-owner/ravely.git"

# WITHOUT the fix, this would read the ops fork's branch (`worktree-agent-abc123`)
# and exit 2. WITH the fix, it reads the managed project's branch
# (`feature/#42-add-foo`, conformant) and exits 0.
PAYLOAD_OK=$(jq -nc \
  --arg cmd "cd $OPS_ROOT_1/workspace/ravely && git push origin feature/#42-add-foo" \
  '{tool_input: {command: $cmd}}')
run_hook "validate-branch-name.sh" "$PAYLOAD_OK" "$OPS_ROOT_1"
assert_exit "valid managed-project branch via cd-target" 0 $?

# WITHOUT the fix, this also exited 2 (wrong reason — read apexyard branch
# instead of the actual non-conformant branch). WITH the fix, this exits 2
# for the right reason — the cd target's branch really is non-conformant.
setup_fake_managed_project "$OPS_ROOT_1" "broken-proj" "garbage-branch-name" \
  "git@github.com:fake-owner/broken-proj.git"
PAYLOAD_BAD=$(jq -nc \
  --arg cmd "cd $OPS_ROOT_1/workspace/broken-proj && git push origin garbage-branch-name" \
  '{tool_input: {command: $cmd}}')
run_hook "validate-branch-name.sh" "$PAYLOAD_BAD" "$OPS_ROOT_1"
assert_exit "non-conformant cd-target branch correctly blocks" 2 $?

# Sanity: no cd prefix, hook still works on $PWD branch.
PAYLOAD_NOCD=$(jq -nc \
  --arg cmd "git push origin main" \
  '{tool_input: {command: $cmd}}')
# The ops fork is on `worktree-agent-abc123` which is non-conformant → exit 2
run_hook "validate-branch-name.sh" "$PAYLOAD_NOCD" "$OPS_ROOT_1"
assert_exit "no cd prefix falls back to PWD branch" 2 $?

echo ""
echo "=== validate-pr-create.sh: cd-target branch read ==="

# A PR title with a real ticket in the managed project's tracker would normally
# need network access to verify; we sidestep that by using `--repo` with a
# fake repo and accepting that the title-format / branch-ID checks fire first.
# The cd-target effect we care about is whether the BRANCH read in
# validate-pr-create.sh comes from the cd target (conformant) or the ops fork
# (non-conformant).

# Use a payload that intentionally has NO --title (so title check is skipped)
# — then the ONLY validator left is the branch-ID check, which is exactly what
# the cd-target fix targets. Without the fix the ops-fork branch
# `worktree-agent-abc123` lacks any TICKET-ID pattern and exits 2.
PAYLOAD_PR_OK=$(jq -nc \
  --arg cmd "cd $OPS_ROOT_1/workspace/ravely && gh pr create" \
  '{tool_input: {command: $cmd}}')
run_hook "validate-pr-create.sh" "$PAYLOAD_PR_OK" "$OPS_ROOT_1"
assert_exit "conformant cd-target branch passes PR-create branch check" 0 $?

PAYLOAD_PR_BAD=$(jq -nc \
  --arg cmd "cd $OPS_ROOT_1/workspace/broken-proj && gh pr create" \
  '{tool_input: {command: $cmd}}')
run_hook "validate-pr-create.sh" "$PAYLOAD_PR_BAD" "$OPS_ROOT_1"
assert_exit "non-conformant cd-target branch blocks PR create" 2 $?

echo ""
echo "=== verify-commit-refs.sh: cd-target tracker resolution ==="

# Set up: managed project's origin is a fake repo that gh CAN'T resolve issues
# in (so any #N reference would be flagged as fabricated — UNLESS the cd-target
# fix isn't applied, in which case the hook reads apexyard's origin instead).
#
# Without network access the tracker lookup fails and the hook bails with a
# WARN (exit 0). To exercise the cd-target path deterministically we can't
# rely on the live `gh issue view` call.
#
# Instead: assert the resolved tracker repo string by capturing the WARN
# message which echoes ${TRACKER_REPO}. We need to force the hook to RUN the
# tracker lookup, which means a payload with a valid -m message containing a
# Closes #N reference.
#
# Workaround: shell out to a bare resolution snippet that mirrors the hook's
# logic — verifies the cd_to_command_target call lands us in the right git
# tree. Cleanest unit-test shape:

(
  cd "$OPS_ROOT_1" || exit 1
  . "$HOOKS_DIR/_lib-cd-target.sh"
  cd_to_command_target "cd $OPS_ROOT_1/workspace/ravely && git commit -m 'stub'"
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  ORIGIN_URL=$(git remote get-url origin 2>/dev/null)
  TRACKER_REPO=$(echo "$ORIGIN_URL" | sed -nE 's|.*[:/]([^/:]+/[^/]+)\.git$|\1|p; s|.*[:/]([^/:]+/[^/]+)$|\1|p' | head -1)
  if [ "$TRACKER_REPO" = "fake-owner/ravely" ]; then
    echo "  PASS  tracker repo resolves from cd target (got '$TRACKER_REPO')"
    exit 0
  else
    echo "  FAIL  tracker repo wrong: expected fake-owner/ravely, got '$TRACKER_REPO'"
    exit 1
  fi
)
TRACKER_RC=$?
TESTS_RUN=$((TESTS_RUN + 1))
if [ $TRACKER_RC -eq 0 ]; then
  TESTS_PASS=$((TESTS_PASS + 1))
else
  TESTS_FAIL=$((TESTS_FAIL + 1))
  FAILURES+=("verify-commit-refs.sh: tracker repo not resolved from cd target")
fi

# And the no-cd fallback: should resolve from $PWD.
(
  cd "$OPS_ROOT_1" || exit 1
  . "$HOOKS_DIR/_lib-cd-target.sh"
  cd_to_command_target "git commit -m 'stub'"
  ORIGIN_URL=$(git remote get-url origin 2>/dev/null)
  TRACKER_REPO=$(echo "$ORIGIN_URL" | sed -nE 's|.*[:/]([^/:]+/[^/]+)\.git$|\1|p; s|.*[:/]([^/:]+/[^/]+)$|\1|p' | head -1)
  if [ "$TRACKER_REPO" = "fake-owner/apexyard" ]; then
    echo "  PASS  no-cd falls back to PWD origin (got '$TRACKER_REPO')"
    exit 0
  else
    echo "  FAIL  no-cd fallback wrong: expected fake-owner/apexyard, got '$TRACKER_REPO'"
    exit 1
  fi
)
NOCD_RC=$?
TESTS_RUN=$((TESTS_RUN + 1))
if [ $NOCD_RC -eq 0 ]; then
  TESTS_PASS=$((TESTS_PASS + 1))
else
  TESTS_FAIL=$((TESTS_FAIL + 1))
  FAILURES+=("verify-commit-refs.sh: no-cd fallback not resolving from PWD")
fi

# --------- summary ---------

echo ""
echo "============================================================"
echo "Tests: $TESTS_RUN  Passed: $TESTS_PASS  Failed: $TESTS_FAIL"
echo "============================================================"
if [ $TESTS_FAIL -ne 0 ]; then
  echo ""
  echo "Failures:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
exit 0
