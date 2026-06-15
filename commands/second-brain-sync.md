---
description: Sync this session's work into the second-brain knowledge base (session report, copied specs/plans, updated functional overview)
---

## Context

- Config: !`cat .claude/second-brain.json 2>/dev/null || echo "MISSING"`
- Git status (uncommitted changes): !`git status --porcelain`
- Current commit: !`git rev-parse HEAD 2>/dev/null || echo "none"`
- Today's date: !`date +%F`
- Superpowers specs in repo: !`ls docs/superpowers/specs/ 2>/dev/null || echo "none"`
- Superpowers plans in repo: !`ls docs/superpowers/plans/ 2>/dev/null || echo "none"`

## Your task

Record this session's work into the second-brain knowledge base.

### 1. Check setup

If the "Config" above is `MISSING`, tell the user to run `/second-brain-init` first and stop here.

Otherwise parse it for `project`, `app`, `knowledgeBasePath`, and `lastSync` (which may be `null`).

### 2. Gather what changed

- **Conversation context**: think back over this session — what was implemented or discussed, what alternatives were considered, and why the chosen approach was picked. This is your primary source for the "Summary" and "Decisions & rationale" sections below.
- **Code changes**:
  - If `lastSync.commit` is set, run `git log <lastSync.commit>..HEAD --oneline` and `git diff <lastSync.commit>..HEAD --stat`.
  - Always also run `git diff HEAD --stat` to catch uncommitted changes.
  - If `lastSync` is `null` (first sync), run `git log -10 --oneline` and `git diff HEAD --stat` for a rough picture, leaning more on conversation context.
- **New superpowers artifacts**: compare the "Superpowers specs/plans in repo" filenames above against what's already in `<knowledgeBasePath>/specs/` and `<knowledgeBasePath>/plans/` (run `ls` on those two folders). Any filename present in the repo lists but not in the knowledge base lists is "new".
- **Handoff for the next session**: based on the conversation, determine the current status of the work (`done`, `in progress`, or `blocked`), the immediate next steps if any, and any open questions or blockers. This is what lets someone resume this work in a future session without re-reading the whole conversation.
- **Continuation link**: if this conversation began with `/second-brain-resume` loading a previous session report, note that report's date, topic, and filename — the new report should link back to it as "Continues from".

If there are no code changes, no new superpowers artifacts, and nothing meaningful was discussed/decided this session, tell the user there's nothing to sync and stop here.

### 3. Copy new superpowers artifacts

For each new spec file found in step 2:

```bash
cp "docs/superpowers/specs/<file>" "<knowledgeBasePath>/specs/<file>"
```

For each new plan file:

```bash
cp "docs/superpowers/plans/<file>" "<knowledgeBasePath>/plans/<file>"
```

Keep the original filenames.

### 4. Write the session report

Pick a short kebab-case slug summarizing the session topic (e.g. `keycloak-auth`). Use the "Today's date" from the context above as `<date>`.

Target file: `<knowledgeBasePath>/sessions/<date>-<slug>.md`.

- If this file does **not** exist yet, create it:

```markdown
# Session: <Topic> — <date>

<if this conversation began by resuming a previous session via `/second-brain-resume`, add this line here: "Continues from: [<date> - <topic>](<filename>)" (relative to this file, so same `sessions/` folder — no `../`). Omit this line otherwise.>

## Summary

<what was done, in prose, based on the conversation and code changes from step 2>

## Decisions & rationale

- Decision: <what was decided>
  Why: <reasoning, trade-offs, constraints that drove it>

<repeat for each notable decision. If there were none, write a single line: "No significant decisions this session — implementation followed the existing plan/spec directly.">

## Superpowers artifacts

- Spec: [<title>](../specs/<filename>)
- Plan: [<title>](../plans/<filename>)

<omit this entire section if no new specs/plans were copied in step 3>

## Code changes

- `<path>` — <what changed and why>
<one line per significant file from the git diff/log in step 2>

## Handoff / Next steps

- Status: <done | in progress | blocked>
- Next steps: <what to pick up first in the next session, or "None — work is complete.">
- Open questions / blockers: <anything unresolved, or "None.">
```

- If this file **already exists** (a sync already happened today for this topic), append to it:

```markdown

---

## Update — <current time as HH:MM>

<same Summary / Decisions & rationale / Superpowers artifacts / Code changes / Handoff structure, covering only what's new since the previous entry today>
```

### 5. Update FUNCTIONAL.md

Read `<knowledgeBasePath>/FUNCTIONAL.md`.

For each feature/module touched this session:

- Find the existing `### <Feature>` section that matches by topic (use your judgement). If none matches, add a new `### <Feature>` section under `## Modules / Features`.
- Rewrite that section's body to contain, in this order:
  1. A 2-3 sentence description of the **current** state of that feature (describe what it does now, not a changelog of today's changes).
  2. `- Status: <done | in progress | blocked>` — taken from the "Handoff / Next steps" section of the session report written in step 4; replace any previous "Status" line for this feature.
  3. `- Spec: [<title>](specs/<filename>)` — only if a spec exists for this feature (from this or a prior sync); update the link if a newer spec supersedes an older one.
  4. `- Plan: [<title>](plans/<filename>)` — same rule as spec.
  5. `- Last session: [<date> - <topic>](sessions/<filename>)` — always point to the session report from step 4, replacing any previous "Last session" line for this feature.

Only the latest session link per feature is kept in `FUNCTIONAL.md`; remove older ones (they remain reachable in the `sessions/` folder).

### 5b. Rebuild the Open Items section

Regenerate the `## Open Items` section (positioned after `## Stack & Architecture` and before `## Modules / Features` — add it there if it doesn't exist yet, e.g. in a `FUNCTIONAL.md` written before this section existed):

- Scan **all** `### <Feature>` sections (not just the ones touched this sync) for their `- Status:` and `- Last session:` lines.
- For each feature whose status is `in progress` or `blocked`, add a line: `- [<status>] <Feature> — [<date> - <topic>](sessions/<filename>)` (reuse that feature's "Last session" link).
- If no feature is `in progress` or `blocked`, write a single line: "No open items — all tracked features are up to date."

Write the updated `FUNCTIONAL.md` back.

### 6. Update the config

Get the current UTC timestamp (`date -u +%Y-%m-%dT%H:%M:%SZ`) and current commit (`git rev-parse HEAD`, or `null` if no commits exist). Rewrite `.claude/second-brain.json`:

```json
{
  "project": "<project>",
  "app": "<app>",
  "knowledgeBasePath": "<knowledgeBasePath>",
  "lastSync": {
    "timestamp": "<timestamp>",
    "commit": "<commit-or-null>"
  }
}
```

### 7. Offer cleanup

If any files were copied in step 3, list them for the user and ask: "These files are now saved in the knowledge base. Delete them from `docs/superpowers/specs|plans` in this repo?" Delete only the ones the user confirms:

```bash
rm "docs/superpowers/specs/<file>"
rm "docs/superpowers/plans/<file>"
```

### 8. Report

Summarize for the user: the session report path written, which `FUNCTIONAL.md` sections were updated, and which files were copied (and deleted, if any).
