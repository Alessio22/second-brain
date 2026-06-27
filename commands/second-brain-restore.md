---
description: Restore CLAUDE.md and memory.md from the knowledge base (use after cloning a repo fresh)
---

## Context

- Config: !`cat .claude/second-brain.json 2>/dev/null || echo "MISSING"`
- Current directory: !`pwd`

## Your task

Restore `CLAUDE.md` and `.claude/memory.md` from the knowledge base into this repo.

### 1. Check setup

If "Config" is `MISSING`, tell the user to run `/second-brain-set-path` first (to link this repo to a knowledge base) and stop here.

Otherwise parse `project`, `app`, and `knowledgeBasePath`.

### 2. Verify the knowledge base exists

Check that `<knowledgeBasePath>` exists on disk:

```bash
test -d "<knowledgeBasePath>" && echo "ok" || echo "missing"
```

If it outputs `missing`, tell the user: "Knowledge base not found at `<knowledgeBasePath>`. Have you run `/second-brain-set-path` with the correct path?" and stop here.

### 3. Find what is available to restore

Check which files exist in the KB:

```bash
test -f "<knowledgeBasePath>/CLAUDE.md" && echo "CLAUDE.md: yes" || echo "CLAUDE.md: no"
test -f "<knowledgeBasePath>/memory.md" && echo "memory.md: yes" || echo "memory.md: no"
```

If neither file exists in the KB, tell the user: "Nothing to restore — `CLAUDE.md` and `memory.md` were not found in `<knowledgeBasePath>`. Run `/second-brain-sync` from a working machine first to back them up." and stop here.

### 4. Restore each file

For each file present in the KB:

**CLAUDE.md** (if `<knowledgeBasePath>/CLAUDE.md` exists):
- Check whether `CLAUDE.md` already exists in the repo root.
- If it exists, ask: "CLAUDE.md already exists in this repo. Overwrite with the version from the KB?" Only proceed if confirmed.
- Copy:

```bash
cp "<knowledgeBasePath>/CLAUDE.md" "CLAUDE.md"
```

**memory.md** (if `<knowledgeBasePath>/memory.md` exists):
- Check whether `.claude/memory.md` already exists.
- If it exists, ask: "`.claude/memory.md` already exists. Overwrite with the version from the KB?" Only proceed if confirmed.
- Create `.claude/` if it doesn't exist: `mkdir -p .claude`
- Copy:

```bash
cp "<knowledgeBasePath>/memory.md" ".claude/memory.md"
```

### 5. Report

Summarize what was restored:

```
✓ Restore complete from: <knowledgeBasePath>

Files restored:
- <list each file copied with its destination>

Files not found in KB (skipped):
- <list each file that was absent, or "(none)" if all were found>
```
