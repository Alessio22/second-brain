---
name: second-brain-resume
description: Resume an in-progress or blocked session from the second-brain knowledge base. Use when the user asks to resume work, continue a previous session, or pick up where they left off.
---

## Step 0: Gather context

Run this to understand the current state before doing anything:

```bash
cat .claude/second-brain.json 2>/dev/null || echo "MISSING"   # config
git branch --show-current 2>/dev/null   # current branch
```

## Your task

Help the user pick up work that was left in progress or blocked in a previous session.

### 1. Check setup

If the config from Step 0 is `MISSING`, tell the user to run the second-brain-init skill first and stop here.

Otherwise parse it for `project`, `app`, and `knowledgeBasePath`.

### 2. Find incomplete sessions

The functional overview file is `<knowledgeBasePath>/FUNCTIONAL-<app>.md`. If it doesn't exist yet but a legacy `<knowledgeBasePath>/FUNCTIONAL.md` does (from before this file was renamed to include the app name), migrate it first:

```bash
cd "<knowledgeBasePath>" && (git mv FUNCTIONAL.md "FUNCTIONAL-<app>.md" 2>/dev/null || mv FUNCTIONAL.md "FUNCTIONAL-<app>.md")
```

Read `<knowledgeBasePath>/FUNCTIONAL-<app>.md` and find the `## Open Items` section.

- If the section doesn't exist (an older `FUNCTIONAL-<app>.md` from before this section was introduced), tell the user to run the second-brain-sync skill once — it will add the section — and stop here.
- If it says "No open items — all tracked features are up to date" (or equivalent), tell the user there's nothing incomplete to resume and stop here.
- Otherwise, each line has the form `- [<status>] <Feature> — [<date> - <topic>](sessions/<filename>)`.

### 3. Let the user choose

Present the entries from `## Open Items` as a numbered list (feature, status, date/topic). Ask the user which one to resume (or whether to skip).

### 4. Load full context for the chosen session

- Read the full session report `<knowledgeBasePath>/sessions/<filename>`.
- Read any spec/plan files linked from its "Superpowers artifacts" section(s).
- Read the `### <Feature>` section in `FUNCTIONAL-<app>.md` for the current overall description of that feature.
- If this report itself starts with a "Continues from" line, you may also skim the linked earlier session for additional background.

### 4b. Check the recorded branch

The loaded session report's "Handoff / Next steps" section may contain a `- Branch:` line (older reports may not — skip this step if absent).

Compare it to the "current branch" output from Step 0.

- If they match, no action needed.
- If they differ:
  - Check whether the recorded branch still exists locally: `git branch --list <branch>`. If it's gone, tell the user the original branch (`<branch>`) no longer exists — probably merged or deleted — and move on.
  - If it exists, check `git status --porcelain`. If there are uncommitted changes, tell the user this session was on branch `<branch>` but they have local changes on the current branch — they should commit or stash those before switching, and don't offer a checkout.
  - If it exists and the working tree is clean, ask the user whether to switch to `<branch>` now. If yes, run `git checkout <branch>`.

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

Keep in mind for later: if this conversation is eventually recorded with the second-brain-sync skill, the new session report should link back to this one as "Continues from: [<date> - <topic>](<filename>)".
