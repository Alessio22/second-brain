# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Claude Code plugin (`second-brain`) that turns a project's [superpowers](https://github.com/obra/superpowers) specs/plans and session work into a portable markdown "second brain" knowledge base (e.g. an Obsidian vault), kept outside the repo.

There is no application code, build step, linter, or test suite — the entire "implementation" is three slash-command prompt files under `commands/`. Each file is a markdown prompt with frontmatter, a `## Context` section of shell snippets (`!`command``) that get executed and injected when the command runs, and a `## Your task` section of step-by-step instructions that Claude follows directly when a user invokes the command.

## Repo layout

- `.claude-plugin/plugin.json` — Claude Code plugin metadata (name, version, description, author).
- `.claude-plugin/marketplace.json` — Claude Code marketplace listing so this repo can be added as a plugin source.
- `commands/second-brain-init.md` — `/second-brain-init`, one-time per-repo setup.
- `commands/second-brain-sync.md` — `/second-brain-sync`, run at checkpoints to record session work.
- `commands/second-brain-resume.md` — `/second-brain-resume`, picks up an in-progress or blocked session.
- `hooks/hooks.json` and `hooks/check-unsync.sh` — a `Stop` hook (Claude Code only) that reminds the user to run `/second-brain-sync` once per session when there's unsynced work (new commits vs. `lastSync.commit`, uncommitted changes, or uncopied `docs/superpowers/specs|plans` files). `hooks/test-check-unsync.sh` is its test harness (`bash hooks/test-check-unsync.sh`).
- `.agents/plugins/marketplace.json` — Codex marketplace listing so this repo can be added via `codex plugin marketplace add` + `codex plugin add`. Points at `./plugins/second-brain` as the plugin source.
- `plugins/second-brain/.codex-plugin/plugin.json` — Codex plugin manifest (name, version, description, author, and a `skills` path pointing to `./.agents/skills/`).
- `plugins/second-brain/.agents/skills/second-brain-init/SKILL.md`, `.../second-brain-sync/SKILL.md`, and `.../second-brain-resume/SKILL.md` — Codex CLI [Agent Skills](https://developers.openai.com/codex/custom-prompts) versions of the same three commands, referenced by `plugins/second-brain/.codex-plugin/plugin.json`. Functionally equivalent to the `commands/*.md` files but without Claude-specific frontmatter or `!`command`` context injection — the skill body tells the agent to run the context-gathering commands itself as "Step 0". Keep these in sync with `commands/*.md` when updating the workflow.
- `docs/superpowers/specs/` and `docs/superpowers/plans/` — this repo's own superpowers design spec and plan for the plugin itself (dogfooding the workflow these commands support).

## Architecture: the three commands

### `/second-brain-init`

One-time setup linking a repo to a knowledge base folder. Reads `CLAUDE.md` (or scans the codebase if absent), asks the user for a project name, app name, and knowledge base root path, then:

1. Creates `<knowledgeBasePath>/{specs,plans,sessions,scripts}/` (where `knowledgeBasePath = <kb-root>/<project>/<app>`).
2. Generates `<knowledgeBasePath>/FUNCTIONAL-<app>.md` from a fixed template (Stack & Architecture + Open Items + Modules/Features sections).
3. Writes `.claude/second-brain.json` with `{project, app, knowledgeBasePath, lastSync: null}`.
4. Ensures `.claude/second-brain.json` is gitignored.

If a config already exists, it shows the current mapping and asks whether to keep it or update project/app/path — it never silently regenerates `FUNCTIONAL-<app>.md`.

### `/second-brain-sync`

Run at natural checkpoints (e.g. after finishing a feature). Reads `.claude/second-brain.json` (errors out telling the user to run `/second-brain-init` if missing), then:

1. Gathers what changed: conversation context, `git log`/`git diff` since `lastSync.commit` (or recent history if `lastSync` is `null`), any `docs/superpowers/specs|plans` files not yet copied into the knowledge base, any untracked one-off script files (`.sh`/`.bash`/`.py`/`.rb`/`.js`/`.mjs`/`.ts`/`.ps1`/`.pl`) not yet copied into `<knowledgeBasePath>/scripts/`, and — if this conversation began via `/second-brain-resume` — the resumed session's date/topic/filename for a "Continues from" link.
2. Copies new spec/plan files into `<knowledgeBasePath>/specs/` and `.../plans/`, preserving filenames; copies new script files into `<knowledgeBasePath>/scripts/` (flat, basename only, skipping any that already exist there).
3. Writes/appends a session report at `<knowledgeBasePath>/sessions/<date>-<slug>.md` (optional "Continues from" link, Summary, Decisions & rationale, Superpowers artifacts, Code changes, Scripts, Handoff / Next steps including a `Branch:` line recording the current git branch, or its detached-HEAD form).
4. Updates `FUNCTIONAL-<app>.md`: for each touched feature, rewrites its section to describe the *current* state, its `Status` (`done`/`in progress`/`blocked`, from the session's Handoff section), and links the latest spec/plan/session (only the most recent session link per feature is kept — older ones stay reachable in `sessions/`).
5. Rebuilds the `## Open Items` section by scanning **all** `### <Feature>` sections for `in progress`/`blocked` statuses (not just those touched this sync), adding the section if an older `FUNCTIONAL-<app>.md` doesn't have it yet.
6. Rewrites `.claude/second-brain.json` with a new `lastSync.{timestamp, commit}`.
7. If files were copied from `docs/superpowers/` or one-off scripts were copied to `scripts/`, offers to delete the originals (only on explicit user confirmation).

### `/second-brain-resume`

Picks up work left `in progress` or `blocked` by a previous sync. Reads `.claude/second-brain.json` (errors out telling the user to run `/second-brain-init` if missing), then:

1. Reads the `## Open Items` section of `FUNCTIONAL-<app>.md` (each line: `- [<status>] <Feature> — [<date> - <topic>](sessions/<filename>)`). If the section is missing, tells the user to run `/second-brain-sync` once to generate it.
2. Lists those entries and asks the user to pick one.
3. Loads full context for the chosen session: the session report itself, any linked spec/plan files, and the matching `### <Feature>` section in `FUNCTIONAL-<app>.md`.
4. Checks the recorded `Branch:` line (if present) against the current branch; if they differ and the recorded branch still exists with a clean working tree, offers to `git checkout` it.
5. Checks for staleness: runs `git log --since=<session date>` against the files listed in "Code changes" and warns if they've changed since.
6. Summarizes status, next steps, open questions/blockers, any branch-switch result, and any staleness warning, and offers to continue — noting that a future sync should link back here as "Continues from".

## Key invariants when editing these commands

- The `second-brain.json` schema — `{project, app, knowledgeBasePath, lastSync: {timestamp, commit} | null}` — must stay identical across `second-brain-init.md`, `second-brain-sync.md`, and `second-brain-resume.md`.
- The `FUNCTIONAL-<app>.md` template structure (`## Stack & Architecture`, `## Open Items`, `## Modules / Features`, `### <Feature>` sections) produced by init must match what sync expects to find and edit, and what resume expects to read.
- `sync` and `resume` both migrate a legacy `FUNCTIONAL.md` (from before the app name was added to the filename) to `FUNCTIONAL-<app>.md` if found, before reading it. Keep this migration step identical across both commands and their Codex skill equivalents.
- Every session report's "Handoff / Next steps" section must start with a `- Status: done|in progress|blocked` line — sync's "Rebuild the Open Items section" step relies on this exact `- Status:` prefix in each feature's `FUNCTIONAL-<app>.md` section (which is in turn copied from the session report).
- The line immediately after `- Status:` in "Handoff / Next steps" must be `- Branch: <branch-name>` (or `- Branch: (detached HEAD at <short-sha>)`) — resume's branch-check step relies on this exact `- Branch:` prefix. Older session reports may not have this line; resume must treat its absence as "skip the branch check", not an error.
- The `## Open Items` section in `FUNCTIONAL-<app>.md` is the single source of truth `second-brain-resume.md` reads — it must be rebuilt on every sync from *all* feature sections' current `Status`/`Last session` lines, not just the ones touched that sync.
- A session report's optional leading "Continues from: [...]" line must point to another file in the same `sessions/` folder (no `../`), unlike the spec/plan/script links lower in the same file (which use `../specs/...` / `../plans/...` / `../scripts/...`).
- Relative link paths must stay consistent with the actual layout: `<knowledgeBasePath>/{FUNCTIONAL-<app>.md, specs/, plans/, sessions/, scripts/}` — session reports link out as `../specs/...` / `../plans/...` / `../scripts/...`, while `FUNCTIONAL-<app>.md` links as `specs/...` / `plans/...` / `sessions/...`.
- A session report's `## Scripts` section is omitted entirely (not left empty) when no new scripts were copied that session — same convention as `## Superpowers artifacts`.
- `.claude/second-brain.json` must always remain gitignored (it's a local, machine-specific path mapping).
- All cross-references in generated knowledge-base files use plain relative markdown links, never Obsidian wikilinks, to keep the knowledge base portable.
