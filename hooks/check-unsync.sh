#!/bin/bash
# Stop hook: remind the user to run /second-brain-sync if there's unsynced work.
# Reads hook input JSON on stdin. Never blocks — always exits 0.

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

[ -n "$CWD" ] || exit 0
[ -n "$SESSION_ID" ] || exit 0

CONFIG="$CWD/.claude/second-brain.json"
[ -f "$CONFIG" ] || exit 0

exit 0
