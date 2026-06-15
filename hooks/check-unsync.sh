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

MARKER="/tmp/second-brain-reminded-$SESSION_ID"
[ -f "$MARKER" ] && exit 0

LAST_SYNC_COMMIT=$(jq -r '.lastSync.commit // empty' "$CONFIG")
KB_PATH=$(jq -r '.knowledgeBasePath // empty' "$CONFIG")

UNSYNCED=false

HEAD_COMMIT=$(git -C "$CWD" rev-parse --verify -q HEAD 2>/dev/null || echo "")
if [ -n "$HEAD_COMMIT" ] && [ "$HEAD_COMMIT" != "$LAST_SYNC_COMMIT" ]; then
  UNSYNCED=true
fi

if [ -n "$(git -C "$CWD" status --porcelain 2>/dev/null)" ]; then
  UNSYNCED=true
fi

if [ "$UNSYNCED" = true ]; then
  touch "$MARKER"
  jq -n '{additionalContext: "Hai lavoro non sincronizzato nel second brain (nuovi commit, modifiche non committate, o nuove spec/piani superpowers). Valuta di eseguire /second-brain-sync prima di chiudere la sessione."}'
fi

exit 0
