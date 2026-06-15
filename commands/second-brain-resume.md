---
description: Resume an in-progress or blocked session from the second-brain knowledge base
---

## Context

- Config: !`cat .claude/second-brain.json 2>/dev/null || echo "MISSING"`

## Your task

Help the user pick up work that was left in progress or blocked in a previous session.

### 1. Check setup

If the "Config" above is `MISSING`, tell the user to run `/second-brain-init` first and stop here.

Otherwise parse it for `project`, `app`, and `knowledgeBasePath`.

### 2. Find incomplete sessions

Read `<knowledgeBasePath>/FUNCTIONAL.md` and find the `## Open Items` section.

- If the section doesn't exist (an older `FUNCTIONAL.md` from before this section was introduced), tell the user to run `/second-brain-sync` once — it will add the section — and stop here.
- If it says "No open items — all tracked features are up to date" (or equivalent), tell the user there's nothing incomplete to resume and stop here.
- Otherwise, each line has the form `- [<status>] <Feature> — [<date> - <topic>](sessions/<filename>)`.

### 3. Let the user choose

Present the entries from `## Open Items` as a list (feature, status, date/topic). Use the AskUserQuestion tool to let the user pick one (or let them say "skip" / pick none).

### 4. Load full context for the chosen session

- Read the full session report `<knowledgeBasePath>/sessions/<filename>`.
- Read any spec/plan files linked from its "Superpowers artifacts" section(s).
- Read the `### <Feature>` section in `FUNCTIONAL.md` for the current overall description of that feature.
- If this report itself starts with a "Continues from" line, you may also skim the linked earlier session for additional background.

### 5. Check for staleness

From the "Code changes" section of the session report, collect the file paths touched. Run:

```bash
git log --oneline --since="<session date>" -- <path1> <path2> ...
```

If this returns any commits, warn the user that these files have changed since this session (`<date>`) and briefly list the commits — the code may have moved on, so it's worth a quick look before continuing. If it returns nothing, no warning is needed.

### 6. Summarize and offer to continue

Summarize for the user, in a few sentences:
- What this session was about and what was already done.
- The current status (`in progress` / `blocked`).
- The "Next steps" and "Open questions / blockers" from the session's "Handoff / Next steps" section.
- Any staleness warning from step 5.

Then ask if they'd like to continue with those next steps now.

Keep in mind for later: if this conversation is eventually recorded with `/second-brain-sync`, the new session report should link back to this one as "Continues from: [<date> - <topic>](<filename>)".
