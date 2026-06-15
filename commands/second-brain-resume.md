---
description: Resume an in-progress or blocked session from the second-brain knowledge base
---

## Context

- Config: !`cat .claude/second-brain.json 2>/dev/null || echo "MISSING"`
- Current branch: !`git branch --show-current 2>/dev/null`

## Your task

Help the user pick up work that was left in progress or blocked in a previous session.

### 1. Check setup

If the "Config" above is `MISSING`, tell the user to run `/second-brain-init` first and stop here.

Otherwise parse it for `project`, `app`, and `knowledgeBasePath`.

### 2. Find incomplete sessions

The functional overview file is `<knowledgeBasePath>/FUNCTIONAL-<app>.md`. If it doesn't exist yet but a legacy `<knowledgeBasePath>/FUNCTIONAL.md` does (from before this file was renamed to include the app name), migrate it first:

```bash
cd "<knowledgeBasePath>" && (git mv FUNCTIONAL.md "FUNCTIONAL-<app>.md" 2>/dev/null || mv FUNCTIONAL.md "FUNCTIONAL-<app>.md")
```

Read `<knowledgeBasePath>/FUNCTIONAL-<app>.md` and find the `## Open Items` section.

- If the section doesn't exist (an older `FUNCTIONAL-<app>.md` from before this section was introduced), tell the user to run `/second-brain-sync` once — it will add the section — and stop here.
- If it says "No open items — all tracked features are up to date" (or equivalent), tell the user there's nothing incomplete to resume and stop here.
- Otherwise, each line has the form `- [<status>] <Feature> — [<date> - <topic>](sessions/<filename>)`.

### 3. Let the user choose

Present the entries from `## Open Items` as a list (feature, status, date/topic). Use the AskUserQuestion tool to let the user pick one (or let them say "skip" / pick none).

### 4. Load full context for the chosen session

- Read the full session report `<knowledgeBasePath>/sessions/<filename>`.
- Read any spec/plan files linked from its "Superpowers artifacts" section(s).
- Read the `### <Feature>` section in `FUNCTIONAL-<app>.md` for the current overall description of that feature.
- If this report itself starts with a "Continues from" line, you may also skim the linked earlier session for additional background.

### 4b. Check the recorded branch

The loaded session report's "Handoff / Next steps" section may contain a `- Branch:` line (older reports may not — skip this step if absent).

Compare it to "Current branch" from the Context above.

- If they match, no action needed.
- If they differ:
  - Check whether the recorded branch still exists locally: `git branch --list <branch>`. If it's gone, tell the user the original branch (`<branch>`) no longer exists — probably merged or deleted — and move on.
  - If it exists, check `git status --porcelain`. If there are uncommitted changes, tell the user this session was on branch `<branch>` but they have local changes on the current branch — they should commit or stash those before switching, and don't offer a checkout.
  - If it exists and the working tree is clean, use AskUserQuestion to ask whether to switch to `<branch>` now. If yes, run `git checkout <branch>`.

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
- Any branch-switch result from step 4b.
- Any staleness warning from step 5.

Then ask if they'd like to continue with those next steps now.

Keep in mind for later: if this conversation is eventually recorded with `/second-brain-sync`, the new session report should link back to this one as "Continues from: [<date> - <topic>](<filename>)".
