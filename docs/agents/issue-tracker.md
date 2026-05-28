# Issue tracker: beads (embedded mode)

This repo uses **beads** (`bd`) for issue tracking — a local embedded database initialized at `.beads/`,
tracked by git alongside the code. Run `bd prime` for full workflow context at the start of any session.

## Essential commands

- **Find work**: `bd ready`
- **Create**: `bd create --title="..." --description="..." --type=task|bug|feature --priority=2`
- **Show**: `bd show <id>`
- **List**: `bd list --status=open`
- **Update**: `bd update <id> --claim` / `--assignee=...` / `--title=...` / `--description=...`
- **Close**: `bd close <id>` or `bd close <id> --reason="..."`
- **Comment**: `bd comment <id> --body "..."`
- **Label**: `bd tag <id> <label>` / `bd label remove <id> <label>`
- **Sync**: via `git push` / `git pull` — beads is embedded in the repo, no separate Dolt remote

## Rules

- Use `bd` for ALL task tracking — do NOT use markdown files or TodoWrite for issues.
- Create a beads issue BEFORE writing code; mark in_progress when starting.
- Do NOT use `bd edit` — it opens `$EDITOR` and blocks agents.
- Priority is numeric: 0=critical, 1=high, 2=medium, 3=low, 4=backlog. Not "high"/"medium"/"low".

## When a skill says "publish to the issue tracker"

Run `bd create --title="..." --description="..."`.

## When a skill says "fetch the relevant ticket"

Run `bd show <id>`.
