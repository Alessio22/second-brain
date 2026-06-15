#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/check-unsync.sh"
FAILURES=0

run_hook() {
  local cwd="$1" session_id="$2"
  jq -n --arg cwd "$cwd" --arg sid "$session_id" '{cwd: $cwd, session_id: $sid}' | "$HOOK"
}

assert_no_output() {
  local desc="$1" output="$2"
  if [ -z "$output" ]; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc (expected no output, got: $output)"
    FAILURES=$((FAILURES+1))
  fi
}

assert_reminder() {
  local desc="$1" output="$2"
  if echo "$output" | jq -e '.additionalContext | test("second-brain-sync")' >/dev/null 2>&1; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc (expected reminder, got: $output)"
    FAILURES=$((FAILURES+1))
  fi
}

setup_repo() {
  local dir
  dir=$(mktemp -d)
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Test"
  echo "$dir"
}

write_config() {
  local dir="$1" last_sync_commit="$2" kb_path="$3"
  mkdir -p "$dir/.claude"
  local last_sync_json
  if [ -z "$last_sync_commit" ]; then
    last_sync_json="null"
  else
    last_sync_json="{\"timestamp\":\"2026-01-01T00:00:00Z\",\"commit\":\"$last_sync_commit\"}"
  fi
  cat > "$dir/.claude/second-brain.json" <<EOF
{"project":"test","app":"test","knowledgeBasePath":"$kb_path","lastSync":$last_sync_json}
EOF
}

# Test: no .claude/second-brain.json => silent
dir=$(setup_repo)
output=$(run_hook "$dir" "session-$$-1")
assert_no_output "no config => silent" "$output"
rm -rf "$dir"

if [ "$FAILURES" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAILURES test(s) failed."
  exit 1
fi
