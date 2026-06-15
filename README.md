# second-brain

A Claude Code plugin that saves your coding sessions as linked, navigable markdown notes in a portable "second brain" knowledge base — just folders and markdown, so it works great in Obsidian but isn't tied to it. The goal is to carry context (what was done, why, key decisions) from one session into the next, so future sessions start with memory instead of from scratch.

## What it does

- `/second-brain-init` — one-time setup. Reads `CLAUDE.md` (or scans the codebase), asks where your knowledge base lives, and creates a `FUNCTIONAL.md` overview plus `specs/`, `plans/`, `sessions/` folders for this app.
- `/second-brain-sync` — run at checkpoints (e.g. after finishing a feature). Writes a session report (what was done, why, key decisions, and a handoff section with status, next steps, and open questions so the work can be picked up in a future session) linked to the relevant feature, copies any new [superpowers](https://github.com/obra/superpowers) `docs/superpowers/specs|plans` files into the knowledge base, and updates `FUNCTIONAL.md` to link to the latest spec/plan/session per feature — building up a cross-linked history you and future sessions can navigate.
- `/second-brain-resume` — lists sessions still marked `in progress` or `blocked`, lets you pick one, and loads its session report, linked specs/plans, and the relevant `FUNCTIONAL.md` section so you can continue where you left off.

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

### Claude Code

Add this repo as a plugin source in Claude Code (Settings → Plugins → Add from GitHub: `<your-github-username>/second-brain`), or clone it and point Claude Code's plugin directory at it locally.

### Codex CLI

Add this repo as a [Codex plugin](https://developers.openai.com/codex/plugins) marketplace and install it:

```
/plugin marketplace add <your-github-username>/second-brain
/plugin install second-brain@second-brain
```

This registers the `.agents/skills/second-brain-init`, `.agents/skills/second-brain-sync`, and `.agents/skills/second-brain-resume` [Agent Skills](https://developers.openai.com/codex/custom-prompts) declared in `.codex-plugin/plugin.json`.

Alternatively, copy or symlink the skill folders into one of Codex's skill locations without using the plugin system:

```bash
# Globally, for all projects:
mkdir -p ~/.agents/skills
cp -r .agents/skills/second-brain-init .agents/skills/second-brain-sync .agents/skills/second-brain-resume ~/.agents/skills/

# Or just for one project, from that project's root:
mkdir -p .agents/skills
cp -r /path/to/second-brain/.agents/skills/second-brain-init /path/to/second-brain/.agents/skills/second-brain-sync /path/to/second-brain/.agents/skills/second-brain-resume .agents/skills/
```

Restart Codex (or start a new session) so it picks up the new skills.

## Usage

1. In a project repo, run `/second-brain-init` (Claude Code) — or ask Codex to set up a second brain, which triggers the `second-brain-init` skill. Answer the prompts for project name, app name, and your knowledge base root path (e.g. an Obsidian vault folder).
2. Work normally, optionally using superpowers for specs/plans.
3. At a natural checkpoint, run `/second-brain-sync` (Claude Code) or ask Codex to sync the second brain. It records a session report, links specs/plans, and updates the functional overview.
4. Next time, run `/second-brain-resume` (Claude Code) or ask Codex to resume previous work — it lists sessions that are still `in progress` or `blocked`, and loads the full context for the one you pick.

Both agents share the same `.claude/second-brain.json` config and knowledge base layout, so a repo set up with one works with the other.
