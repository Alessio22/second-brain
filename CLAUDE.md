# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Claude Code plugin (`second-brain`) that turns a project's [superpowers](https://github.com/obra/superpowers) specs/plans and session work into a portable markdown "second brain" knowledge base (e.g. an Obsidian vault), kept outside the repo.

There is no application code, build step, linter, or test suite — the entire "implementation" is two slash-command prompt files under `commands/`. Each file is a markdown prompt with frontmatter, a `## Context` section of shell snippets (`!`command``) that get executed and injected when the command runs, and a `## Your task` section of step-by-step instructions that Claude follows directly when a user invokes the command.

## Repo layout

- `.claude-plugin/plugin.json` — Claude Code plugin metadata (name, version, description, author).
- `.claude-plugin/marketplace.json` — Claude Code marketplace listing so this repo can be added as a plugin source.
- `commands/second-brain-init.md` — `/second-brain-init`, one-time per-repo setup.
- `commands/second-brain-sync.md` — `/second-brain-sync`, run at checkpoints to record session work.
- `.codex-plugin/plugin.json` — Codex plugin manifest (name, version, description, author, and the `skills` it bundles).
- `.agents/plugins/marketplace.json` — Codex marketplace listing so this repo can be added via `/plugin marketplace add` + `/plugin install`.
- `.agents/skills/second-brain-init/SKILL.md` and `.agents/skills/second-brain-sync/SKILL.md` — Codex CLI [Agent Skills](https://developers.openai.com/codex/custom-prompts) versions of the same two commands, referenced by `.codex-plugin/plugin.json`. Functionally equivalent to the `commands/*.md` files but without Claude-specific frontmatter or `!`command`` context injection — the skill body tells the agent to run the context-gathering commands itself as "Step 0". Keep these in sync with `commands/*.md` when updating the workflow.
- `docs/superpowers/specs/` and `docs/superpowers/plans/` — this repo's own superpowers design spec and plan for the plugin itself (dogfooding the workflow these commands support).

## Architecture: the two commands

### `/second-brain-init`

One-time setup linking a repo to a knowledge base folder. Reads `CLAUDE.md` (or scans the codebase if absent), asks the user for a project name, app name, and knowledge base root path, then:

1. Creates `<knowledgeBasePath>/{specs,plans,sessions}/` (where `knowledgeBasePath = <kb-root>/<project>/<app>`).
2. Generates `<knowledgeBasePath>/FUNCTIONAL.md` from a fixed template (Stack & Architecture + Modules/Features sections).
3. Writes `.claude/second-brain.json` with `{project, app, knowledgeBasePath, lastSync: null}`.
4. Ensures `.claude/second-brain.json` is gitignored.

If a config already exists, it shows the current mapping and asks whether to keep it or update project/app/path — it never silently regenerates `FUNCTIONAL.md`.

### `/second-brain-sync`

Run at natural checkpoints (e.g. after finishing a feature). Reads `.claude/second-brain.json` (errors out telling the user to run `/second-brain-init` if missing), then:

1. Gathers what changed: conversation context, `git log`/`git diff` since `lastSync.commit` (or recent history if `lastSync` is `null`), and any `docs/superpowers/specs|plans` files not yet copied into the knowledge base.
2. Copies new spec/plan files into `<knowledgeBasePath>/specs/` and `.../plans/`, preserving filenames.
3. Writes/appends a session report at `<knowledgeBasePath>/sessions/<date>-<slug>.md` (Summary, Decisions & rationale, Superpowers artifacts, Code changes).
4. Updates `FUNCTIONAL.md`: for each touched feature, rewrites its section to describe the *current* state and links the latest spec/plan/session (only the most recent session link per feature is kept — older ones stay reachable in `sessions/`).
5. Rewrites `.claude/second-brain.json` with a new `lastSync.{timestamp, commit}`.
6. If files were copied from `docs/superpowers/`, offers to delete the originals (only on explicit user confirmation).

## Key invariants when editing these commands

- The `second-brain.json` schema — `{project, app, knowledgeBasePath, lastSync: {timestamp, commit} | null}` — must stay identical between `second-brain-init.md` and `second-brain-sync.md`.
- The `FUNCTIONAL.md` template structure (`## Stack & Architecture`, `## Modules / Features`, `### <Feature>` sections) produced by init must match what sync expects to find and edit.
- Relative link paths must stay consistent with the actual layout: `<knowledgeBasePath>/{FUNCTIONAL.md, specs/, plans/, sessions/}` — session reports link out as `../specs/...` / `../plans/...`, while `FUNCTIONAL.md` links as `specs/...` / `plans/...` / `sessions/...`.
- `.claude/second-brain.json` must always remain gitignored (it's a local, machine-specific path mapping).
- All cross-references in generated knowledge-base files use plain relative markdown links, never Obsidian wikilinks, to keep the knowledge base portable.
