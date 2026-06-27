---
description: Update the knowledge base path for this repo (or create the config if missing after a fresh clone)
---

## Context

- Existing config: !`cat .claude/second-brain.json 2>/dev/null || echo "MISSING"`
- Current directory: !`pwd`

## Your task

Update (or create) the `.claude/second-brain.json` config so that future syncs write to the correct knowledge base path.

### 1. Detect which case applies

**Case A — config exists** (output is not `MISSING`): parse `project`, `app`, and `knowledgeBasePath`. Go to step 2A.

**Case B — config is `MISSING`** (no previous init on this machine): go to step 2B.

---

### 2A. Update existing config path

Show the user the current mapping:

```
Current config:
  Project: <project>
  App:     <app>
  KB path: <knowledgeBasePath>
```

Ask: "What is the new knowledge base **root** path?" (the folder that holds all second-brain projects, not the project-specific subfolder — e.g. `/Users/alex/Obsidian` not `/Users/alex/Obsidian/myproject/myapp`).

Validate the input:
- The folder must exist on disk (`test -d "<new-root>"`). If it doesn't, ask again with a clear error.

Reconstruct the full path: `newKnowledgeBasePath = <new-root>/<project>/<app>`.

Check whether that folder exists (`test -d "<newKnowledgeBasePath>"`):
- If it does not exist, ask: "The folder `<newKnowledgeBasePath>` does not exist yet. Create it, or is the path wrong?" If they say create, run `mkdir -p "<newKnowledgeBasePath>/specs" "<newKnowledgeBasePath>/plans" "<newKnowledgeBasePath>/sessions" "<newKnowledgeBasePath>/scripts"`. If they say the path is wrong, ask for the root path again.

Rewrite `.claude/second-brain.json` with the updated `knowledgeBasePath` (keep `project`, `app`, and `lastSync` unchanged):

```json
{
  "project": "<project>",
  "app": "<app>",
  "knowledgeBasePath": "<newKnowledgeBasePath>",
  "lastSync": <existing lastSync value, unchanged>
}
```

Confirm to the user:

```
✓ Path updated:
  Before: <old knowledgeBasePath>
  Now:    <newKnowledgeBasePath>

The next sync will write to: <newKnowledgeBasePath>
```

---

### 2B. Create config from scratch

Tell the user: "No `.claude/second-brain.json` found. Let's create one so you can use `/second-brain-sync` and `/second-brain-restore`."

Ask the following, one at a time:

1. **Knowledge base root path** — the folder that holds all second-brain projects (e.g. `/Users/alex/Obsidian`). Validate it exists (`test -d`); re-ask on failure.
2. **Project name** — e.g. `MyProject`. No slashes.
3. **App name** — e.g. `myapp-dev`. No slashes.

Compute `knowledgeBasePath = <root>/<project>/<app>`.

Check whether `<knowledgeBasePath>` exists (`test -d`):
- If it does not exist, warn the user: "Folder `<knowledgeBasePath>` not found in the KB. Verify the path, or run `/second-brain-init` to initialize a new project from scratch."

Create `.claude/` if it doesn't exist:

```bash
mkdir -p .claude
```

Write `.claude/second-brain.json`:

```json
{
  "project": "<project>",
  "app": "<app>",
  "knowledgeBasePath": "<knowledgeBasePath>",
  "lastSync": null
}
```

Ensure `.claude/second-brain.json` is gitignored. Check `.gitignore` for an entry covering it (directly or via `.claude/`). If none exists, append `.claude/second-brain.json` on its own line.

Confirm to the user:

```
✓ Config created:
  KB:      <root>
  Project: <project>
  App:     <app>
  Full KB path: <knowledgeBasePath>

You can now run /second-brain-restore to recover CLAUDE.md and memory.md from the KB.
```
