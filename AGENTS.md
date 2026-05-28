# AGENTS.md

Canonical playbook for all coding agents working in the Catnip repo. Model-specific quirks live alongside this file (for example `CLAUDE.md`). Always start here, then consult your agent supplement if one exists.

## Project Summary

Catnip is an agent-friendly development environment composed of:

- **Frontend**: React + TypeScript SPA built with Vite, ShadCN UI, Tailwind CSS, and TanStack Router
- **Container**: Unified Go binary (`catnip`) providing CLI tools and JSONRPC-powered APIs
- **Worker**: Cloudflare Worker using Hono for production edge logic

## Repository Layout

```
catnip/
├── src/                 React app (components, routes, hooks, lib, stores, types)
├── worker/              Cloudflare Worker entry `worker/index.ts` and scripts
├── container/           Go application, `just` tasks, and setup files
├── docs/                Additional documentation
├── public/              Static assets served by Vite
├── dist/                Build output (generated)
└── scripts/             Repository maintenance scripts
```

Path aliases are configured so the frontend imports from `@/*` (e.g. `import { cn } from "@/lib/utils"`).

## Core Commands

- `pnpm dev`: Vite dev server at `http://localhost:5173`
- `pnpm dev:mock`: Dev server with mock backend (no container needed)
- `pnpm dev:cf:vite`: SPA dev server with Cloudflare integration flag
- `pnpm dev:cf`: Build SPA then run `wrangler dev` (worker + assets); logs stream to `/tmp/wrangler.log`
- `pnpm build`: Type-check then Vite build to `dist/`
- `pnpm build:fast`: Vite build without type-check (faster iteration)
- `pnpm preview`: Serve the built bundle locally
- `pnpm typecheck` / `pnpm typecheck:worker`: Strict TypeScript validation for app/worker
- `pnpm lint`: Run ESLint over the repo
- `pnpm format:changed`: Prettier on staged or changed files
- `pnpm test`: Run vitest tests
- `pnpm test:ui`: Run vitest with interactive UI
- `pnpm deploy:prod`: Build and deploy to production
- `just build-dev` then `just run-dev`: Containerized Go + frontend development flow

## Coding & Styling Guidelines

- TypeScript is strict; add explicit types when it improves clarity
- Component files are PascalCase `.tsx`; hooks live in `src/hooks` with `use-*.ts` names
- Prefer `@/*` imports over deep relative chains
- ESLint allows unused vars only when prefixed with `_`
- Use Prettier formatting before commits (`pnpm format:changed`)
- Reuse ShadCN theme tokens; avoid custom styling unless required

## Testing Expectations

- Run tests with `pnpm test`; use `pnpm test:ui` for interactive debugging
- Colocate tests as `*.test.ts(x)` next to the code they cover
- Keep tests fast and isolated; mock external dependencies
- Validate end-to-end flows via `pnpm dev` or `pnpm dev:cf`
- Always run `pnpm typecheck` and `pnpm lint` before committing

## Development Environment Notes

- Dev servers auto-rebuild frontend and Go code; assume they are running
- Avoid restarting containers unless explicitly asked—the dev server manages restarts
- For Go changes, run `just build` inside `container/` to ensure compilation
- Tooltip components must use `TooltipPrimitive.Provider`, `.Root`, etc. Never mount `TooltipPrimitive` directly

## Security & Configuration

- Never commit secrets; use Wrangler secrets (e.g. `wrangler secret put GITHUB_APP_PRIVATE_KEY`)
- Local overrides belong in `.env.local`; deployment env vars are defined in `wrangler.jsonc`
- Workspace initialization runs `./setup.sh`; add dependency installs there when needed

## Working With Agents

- Treat `AGENTS.md` as the source of truth for shared workflows
- Keep per-agent documents lean—focus on deviations or ergonomics specific to that model and link back here for the baseline instructions

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
