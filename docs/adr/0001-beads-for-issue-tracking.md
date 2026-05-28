# Use beads for issue tracking

We use [beads](https://github.com/gastownhall/beads) (`bd`) as the issue tracker for this repo rather than GitHub Issues. The database is embedded in the repo under `.beads/` and syncs via `git push` — no external service required. We chose this because issues live alongside the code (no context-switch to a web UI), the CLI-first design works without friction in agent workflows, and the git-native sync model means issue history travels with the branch.

## Considered options

- **GitHub Issues** — the obvious default for a GitHub-hosted repo, but requires network access and `gh` auth in every environment, and issues are decoupled from the branch they were created on.
- **Local markdown (`.scratch/`)** — simpler, but no structured querying, no dependency graph, and no triage state machine.

## Consequences

- `bd` must be installed in every dev environment (handled by `.devcontainer/on-create.sh`).
- Issues are not visible in the GitHub Issues UI; contributors need the CLI.
- `bd dolt push`/`pull` are not used — sync is embedded, so `git push` is sufficient.
