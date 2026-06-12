# second-brain

A Claude Code plugin that turns your project's [superpowers](https://github.com/obra/superpowers) specs, plans, and session decisions into a portable, linked "second brain" knowledge base — just folders and markdown, so it works great in Obsidian but isn't tied to it.

## What it does

- `/second-brain-init` — one-time setup. Reads `CLAUDE.md` (or scans the codebase), asks where your knowledge base lives, and creates a `FUNCTIONAL.md` overview plus `specs/`, `plans/`, `sessions/` folders for this app.
- `/second-brain-sync` — run at checkpoints (e.g. after finishing a feature). Writes a session report (what was done, why, key decisions), copies any new `docs/superpowers/specs|plans` files into the knowledge base, and updates `FUNCTIONAL.md` to link to the latest spec/plan/session per feature.

## Layout produced

```
<knowledge-base-root>/<project>/<app>/
  FUNCTIONAL.md
  specs/2026-06-08-keycloak-auth-design.md
  plans/2026-06-08-keycloak-auth.md
  sessions/2026-06-12-keycloak-auth.md
```

Each repo gets a local, gitignored `.claude/second-brain.json` recording the mapping to its knowledge base folder and the last sync point.

## Install

Add this repo as a plugin source in Claude Code (Settings → Plugins → Add from GitHub: `<your-github-username>/second-brain`), or clone it and point Claude Code's plugin directory at it locally.

## Usage

1. In a project repo, run `/second-brain-init` once. Answer the prompts for project name, app name, and your knowledge base root path (e.g. an Obsidian vault folder).
2. Work normally, optionally using superpowers for specs/plans.
3. At a natural checkpoint, run `/second-brain-sync`. It records a session report, links specs/plans, and updates the functional overview.
