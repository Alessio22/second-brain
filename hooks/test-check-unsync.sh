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
  # .claude/ is gitignored in real repos (per second-brain.json invariants), so
  # writing the config there shouldn't itself register as an uncommitted change.
  # Use the local exclude file so this doesn't add any tracked/untracked files.
  echo ".claude/" >> "$dir/.git/info/exclude"
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

# Test: new commit since lastSync=null => reminder
dir=$(setup_repo)
echo "hello" > "$dir/file.txt"
git -C "$dir" add file.txt
git -C "$dir" commit -q -m "init"
kb=$(mktemp -d)
write_config "$dir" "" "$kb"
output=$(run_hook "$dir" "session-$$-2")
assert_reminder "new commit since lastSync=null => reminder" "$output"
rm -f "/tmp/second-brain-reminded-session-$$-2"
rm -rf "$dir" "$kb"

# Test: HEAD == lastSync.commit, no other changes => silent
dir=$(setup_repo)
echo "hello" > "$dir/file.txt"
git -C "$dir" add file.txt
git -C "$dir" commit -q -m "init"
head=$(git -C "$dir" rev-parse HEAD)
kb=$(mktemp -d)
write_config "$dir" "$head" "$kb"
output=$(run_hook "$dir" "session-$$-3")
assert_no_output "synced state => silent" "$output"
rm -rf "$dir" "$kb"

# Test: empty repo (zero commits), lastSync=null => silent
dir=$(setup_repo)
kb=$(mktemp -d)
write_config "$dir" "" "$kb"
output=$(run_hook "$dir" "session-$$-4")
assert_no_output "empty repo, no commits => silent" "$output"
rm -rf "$dir" "$kb"

# Test: second call with same session_id => silent (already reminded)
dir=$(setup_repo)
echo "hello" > "$dir/file.txt"
git -C "$dir" add file.txt
git -C "$dir" commit -q -m "init"
kb=$(mktemp -d)
write_config "$dir" "" "$kb"
sid="session-$$-4"
run_hook "$dir" "$sid" > /dev/null
output=$(run_hook "$dir" "$sid")
assert_no_output "second call same session => silent" "$output"
rm -f "/tmp/second-brain-reminded-$sid"
rm -rf "$dir" "$kb"

# Test: HEAD == lastSync.commit but uncommitted changes exist => reminder
dir=$(setup_repo)
echo "hello" > "$dir/file.txt"
git -C "$dir" add file.txt
git -C "$dir" commit -q -m "init"
head=$(git -C "$dir" rev-parse HEAD)
echo "more" >> "$dir/file.txt"
kb=$(mktemp -d)
write_config "$dir" "$head" "$kb"
output=$(run_hook "$dir" "session-$$-5")
assert_reminder "uncommitted changes => reminder" "$output"
rm -f "/tmp/second-brain-reminded-session-$$-5"
rm -rf "$dir" "$kb"

if [ "$FAILURES" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAILURES test(s) failed."
  exit 1
fi
