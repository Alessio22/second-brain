---
description: One-time setup linking this repo to a second-brain knowledge base (e.g. an Obsidian vault folder)
---

## Context

- Current directory: !`pwd`
- Existing config (if any): !`cat .claude/second-brain.json 2>/dev/null || echo "none"`
- CLAUDE.md (if present): !`cat CLAUDE.md 2>/dev/null || echo "none"`
- Repo root folder name: !`basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`
- Parent folder name: !`basename "$(dirname "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"`

## Your task

Set up this repository to use a "second brain" knowledge base: a folder of markdown files (e.g. an Obsidian vault) that holds a functional overview, copies of superpowers specs/plans, and per-session reports for this app.

### 1. Check for existing setup

If the "Existing config" above is not `none`, show the user its current `project`, `app`, and `knowledgeBasePath`, and ask whether they want to:
- Keep it as-is (stop here), or
- Update the project/app name or knowledge base path (go to step 3 with the new values, then re-run step 6 to rewrite the config — do not regenerate `FUNCTIONAL.md` from scratch; just confirm the target folders exist, creating any that are missing).

If the existing config is `none`, continue to step 2.

### 2. Gather context for the functional overview

- If `CLAUDE.md` content is available above (not `none`), use it as your primary source for stack, architecture, and module structure.
- If `CLAUDE.md` is `none`, do a lightweight scan: look at the top-level directory structure, package manifest (`package.json`, `*.csproj`, `pom.xml`, `pyproject.toml`, etc.), and any existing `README.md` to understand the stack and main modules. Keep this scan quick — a few minutes, not a deep audit.

### 3. Ask the user for the mapping

Ask the user the following, one question at a time (multiple choice where sensible, with the suggested defaults below):

1. **Project name** — default: the "Parent folder name" from the context above (e.g. if the repo is at `~/projects/whesp/whesp-platform/whesp-sicura-client`, the parent folder is `whesp-platform` — use your judgement, walking further up if the immediate parent looks like an intermediate grouping folder rather than the product name). For single-repo projects, suggest the repo folder name itself for both project and app.
2. **App name** — default: the "Repo root folder name" from the context above.
3. **Knowledge base root path** — the absolute path to the folder that holds all second-brain projects (e.g. an Obsidian vault root). No default unless the user already mentioned one earlier in this conversation, in which case suggest that.

### 4. Create the knowledge base folders

Compute `knowledgeBasePath = <kb-root>/<project>/<app>`. Create it:

```bash
mkdir -p "<knowledgeBasePath>/specs" "<knowledgeBasePath>/plans" "<knowledgeBasePath>/sessions"
```

### 5. Generate FUNCTIONAL.md

Write `<knowledgeBasePath>/FUNCTIONAL.md` using this template, filled in from what you learned in step 2. Do not invent specs, plans, or session links — those are added by `/second-brain-sync`.

```markdown
# <App Name> — Functional Overview

> Second brain index for this project. Updated by `/second-brain-sync`.

## Stack & Architecture

<2-5 sentences: language/framework, key libraries, high-level structure>

## Modules / Features

### Overview

<1-2 sentences describing the app's overall purpose>

No feature-specific sessions recorded yet. Run `/second-brain-sync` after working on a feature to populate this section.
```

If `CLAUDE.md` or your scan revealed clear, distinct feature areas already, you may add one `### <Feature>` subsection per area instead of (or in addition to) `### Overview`, each with a 1-2 sentence description and no links yet.

### 6. Write the config file

Create `.claude/second-brain.json` (create the `.claude` directory if it doesn't exist):

```json
{
  "project": "<project>",
  "app": "<app>",
  "knowledgeBasePath": "<knowledgeBasePath>",
  "lastSync": null
}
```

### 7. Ensure it's gitignored

Check `.gitignore` for an entry covering `.claude/second-brain.json` (either directly or via a broader `.claude/` ignore). If none exists, append `.claude/second-brain.json` on its own line (create `.gitignore` if it doesn't exist).

### 8. Report

Tell the user:
- The knowledge base path created (`<knowledgeBasePath>`)
- That `FUNCTIONAL.md` was created there
- That `.claude/second-brain.json` was created and gitignored
- That they can run `/second-brain-sync` at checkpoints to keep the knowledge base up to date
