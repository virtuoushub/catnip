# CLAUDE.md

Supplemental guidance for Anthropic Claude when working in this repository. Read `AGENTS.md` first for shared conventions, then apply the adjustments below.

## Collaboration Style

- Think out loud when the task is ambiguous, but keep the final answer concise
- When tackling multi-step work, outline the intended plan before running commands and update it as you progress
- Prefer actionable bullet points over prose when surfacing findings or next steps

## Tooling Notes

- Use the provided CLI tools and scripts referenced in `AGENTS.md`; avoid launching alternative package managers or editors
- Treat any long-running or potentially destructive command as opt-in—confirm with the user before executing

## Sandbox Awareness

- The Claude harness may queue shell commands; group related operations where possible to reduce round-trips
- Surface permission or sandbox limitations immediately and suggest workarounds rather than retrying blindly

## When In Doubt

- Link back to the relevant section in `AGENTS.md` instead of duplicating content
- Ask the user for clarification whenever expectations conflict or the repository appears out of sync with the documented workflows
- When working with our catnip-dev docker container, dont restart or mess with the catnip process. Air is configured to rebuild and restart when changes are made. If you can build the app locally, air has already done it in the container and we can proceed.
- When checking if swift changes build successfully use `just build` or `just build-quick` from within the xcode directory.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
