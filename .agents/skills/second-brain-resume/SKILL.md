---
name: second-brain-resume
description: Resume an in-progress or blocked session from the second-brain knowledge base. Use when the user asks to resume work, continue a previous session, or pick up where they left off.
---

## Step 0: Gather context

Run this to understand the current state before doing anything:

```bash
cat .claude/second-brain.json 2>/dev/null || echo "MISSING"   # config
```

## Your task

Help the user pick up work that was left in progress or blocked in a previous session.

### 1. Check setup

If the config from Step 0 is `MISSING`, tell the user to run the second-brain-init skill first and stop here.

Otherwise parse it for `project`, `app`, and `knowledgeBasePath`.

### 2. Find incomplete sessions

List session files:

```bash
ls "<knowledgeBasePath>/sessions/"*.md 2>/dev/null
```

For each file, get its current status — sessions can contain multiple `## Update — HH:MM` blocks, so only the **last** `Status:` line in the file reflects the current state:

```bash
grep "^- Status:" "<file>" | tail -1
```

Keep only the files whose last status is `in progress` or `blocked`.

If none are found, tell the user there's nothing incomplete to resume and stop here.

### 3. Let the user choose

Present the matching sessions as a numbered list, one per line: date and topic (from the filename, e.g. `2026-06-12-keycloak-auth.md`), plus the status. Ask the user which one to resume (or whether to skip).

### 4. Load full context for the chosen session

- Read the full session report `<knowledgeBasePath>/sessions/<file>`.
- Read any spec/plan files linked from its "Superpowers artifacts" section(s).
- Read `<knowledgeBasePath>/FUNCTIONAL.md` and find the `### <Feature>` section whose "Last session" link points to this file, for the current overall description of that feature.

### 5. Summarize and offer to continue

Summarize for the user, in a few sentences:
- What this session was about and what was already done.
- The current status (`in progress` / `blocked`).
- The "Next steps" and "Open questions / blockers" from the session's "Handoff / Next steps" section.

Then ask if they'd like to continue with those next steps now.
