# PRD: Catnip — Run Claude Code Everywhere

> Current-state product requirements, reverse-engineered from the repo. Requirements are written in **EARS** (Easy Approach to Requirements Syntax): "shall" statements are normative; user stories provide intent. See beads memory `convention-favor-ears-easy-approach-to-requirements-syntax`.

## Problem Statement

As an AI engineer I want to keep Claude Code (and similar coding agents) running productively for as long as possible, but in practice this is hard:

- Agents work best fully sandboxed with all their tools, so I can safely use `--dangerously-skip-permissions` — yet setting up and maintaining such a sandbox is fiddly.
- Running several agents at once means juggling many git worktrees and many terminal sessions; I lose track of which agent did what, and reviewing their changes is painful.
- I want to start, monitor, and steer agents when I'm away from my desk — from a phone or a browser tab — not only from the machine where the container runs.
- I want to preview the services an agent spins up (web apps, notebooks, APIs) without manual port plumbing.

## Solution

Catnip is a self-hostable, containerized development environment that runs coding agents and manages their git work for me. It runs as a single Go binary (the **catnip binary**) inside a **container** (Docker or Apple's Container SDK), and exposes a React **web UI**, JSONRPC/HTTP APIs, an SSH endpoint, and a built-in git server. A Cloudflare **worker** (`catnip.run`) provides a production edge and a **codespace proxy** so I can reach a GitHub Codespace running Catnip from anywhere, including a native **iOS app**.

Each agent runs in its own **workspace** (a git worktree) named with a random cat name. Catnip periodically checkpoints the agent's changes by committing them to a **workspace ref** (`refs/catnip/<catname>`). Once a Claude session earns a title, the workspace **graduates** to a human-friendly **synced branch** (e.g. `feature/...`), which Catnip then keeps in sync bidirectionally — so I can review or check out an agent's work from my host at any time. Catnip auto-detects ports the workspace opens and forwards/proxies them to the host. I can open terminals and **Claude sessions** through the web UI, the CLI, or SSH, and operate them remotely on mobile.

## User Stories

1. As an AI engineer, I want each agent to run in an isolated container, so that I can grant it broad permissions without risking my host.
2. As an AI engineer, I want each agent session to get its own git worktree, so that parallel agents never clobber each other's working trees.
3. As an AI engineer, I want changes an agent makes to be committed automatically, so that no work is lost and every step is reviewable.
4. As an AI engineer, I want each workspace's commits mirrored onto a normally-named branch, so that I can `git checkout` and review the work outside the container.
5. As an AI engineer, I want to fetch a workspace's branch to my host via a built-in git remote, so that I can integrate agent work into my normal git flow.
6. As an AI engineer, I want to spawn many Claude sessions at once and see them organized, so that I can parallelize independent tasks.
7. As an AI engineer, I want to open a full terminal to any workspace from the web UI, so that I can intervene directly when an agent gets stuck.
8. As a mobile user, I want to interact with a running Claude session's terminal from my phone, so that I can keep an agent moving while I'm away from my desk.
9. As a mobile user, I want catnip.run to start my Codespace if it's asleep and route me to it, so that I don't need to touch the GitHub UI first.
10. As an AI engineer, I want services my workspace starts to be auto-detected and forwarded to the host, so that I can preview them without manual port mapping.
11. As an AI engineer, I want a stable `PORT` env var per workspace, so that my dev server binds somewhere predictable and free.
12. As an AI engineer, I want services reachable through the UI proxy at `/$PORT`, so that I can preview them even when a host port is taken.
13. As an AI engineer, I want `ssh catnip` and Remote-SSH support, so that I can use Cursor/VS Code against the container.
14. As an AI engineer, I want `setup.sh` run on workspace creation, so that my project's dependencies are installed before an agent starts.
15. As an AI engineer, I want to pass host env vars into the container with `-e`, so that agents inherit my API keys and provider config.
16. As an AI engineer, I want to pin language runtime versions via `CATNIP_*_VERSION`, so that the sandbox matches my project's toolchain.
17. As an AI engineer, I want Docker-in-Docker via `--dind`, so that agents can build and run containers for multi-service projects.
18. As a contributor, I want to install Catnip as a devcontainer feature, so that I control the exact environment my agents run in.
19. As an AI engineer, I want to run `catnip run` from inside a git repo, so that my repo is mounted and a default workspace is created automatically.
20. As an AI engineer, I want to review an agent's diff in the web UI, so that I can decide whether to keep, amend, or discard its changes.
21. As an AI engineer, I want Catnip to recover gracefully after a restart, so that I don't lose track of in-flight workspaces and sessions.
22. As a self-hoster, I want to run Catnip locally with one install command, so that I can try it without cloud infrastructure.
23. As a privacy-conscious user, I want my temporary Codespace credentials encrypted and pruned, so that remote access doesn't leave long-lived secrets around.
24. As an AI engineer, I want to open a workspace as a PR-ready branch, so that I can move agent work straight into code review.
25. As a developer of Catnip, I want to run it in dev mode against its own repo, so that I can dogfood changes quickly.

## Requirements (EARS)

### Container runtime & sandboxing

- R1 (Ubiquitous): The catnip binary shall run all workspace code inside a container using either Docker or Apple's Container SDK.
- R2 (Ubiquitous): The container shall come pre-provisioned with node, python, golang, gcc, and rust toolchains.
- R3 (Event-driven): When a `CATNIP_NODE_VERSION`, `CATNIP_PYTHON_VERSION`, `CATNIP_RUST_VERSION`, or `CATNIP_GO_VERSION` variable is set at boot, the container shall install the requested runtime version.
- R4 (Event-driven): When `catnip run` is invoked with one or more `-e` arguments, the catnip binary shall expose those environment variables to all terminals and agent sessions in the container.
- R5 (Where, `--dind`): Where Docker-in-Docker is enabled, the container shall mount the host Docker socket (at `/var/run/docker-host.sock`) and expose it via a proxy socket at `/var/run/docker.sock` so workspace processes can run `docker` commands.
- R6 (Where, devcontainer): Where Catnip is installed as the `ghcr.io/wandb/catnip/feature` devcontainer feature, the catnip binary shall start automatically and serve on port 6369.

### Workspace & worktree management

- R7 (Event-driven): When `catnip run` is executed inside a git repository, the catnip binary shall mount the repository and create a default workspace.
- R8 (Event-driven): When a new workspace is created, the catnip binary shall create a dedicated git worktree for it.
- R9 (Event-driven): When a workspace is created, the catnip binary shall run the repository's `setup.sh` (if present), in a PTY, before the workspace is used.
- R10 (Ubiquitous): The catnip binary shall assign each new workspace a random cat name (e.g. `cotton`) used for its workspace ref `refs/catnip/<catname>`, applying an adjective prefix to resolve collisions.

### Auto-commit & branch synchronization

- R11 (State-driven): While a Claude session is running in a workspace, the catnip binary shall periodically checkpoint uncommitted changes by committing them to the workspace ref `refs/catnip/<catname>` (timer/title-driven checkpointing, not a commit per file change).
- R11a (If-then): If commit signing fails during a checkpoint, then the catnip binary shall retry the commit with signing disabled rather than dropping the checkpoint.
- R12 (Event-driven): When a Claude session acquires a title, the catnip binary shall generate a semantic "nice" branch name (one of the `feature/chore/refactor/bug/docs/test/style/perf/fix` prefixes), record the workspace→branch mapping in git config, and rename the workspace to that branch ("graduation").
- R12a (Event-driven): When the workspace ref advances after graduation, the catnip binary shall sync the nice branch to match the workspace ref.
- R12b (Event-driven): When the nice branch is updated outside the container, the catnip binary shall sync those changes back into the workspace ref (bidirectional sync).
- R13 (Ubiquitous): The catnip binary shall make the nice branch checkout-able from the host, and shall maintain a `catnip/<catname>` preview branch reflecting uncommitted workspace state for review outside the container.
- R14 (Event-driven): When a user runs `git fetch catnip` on the host with the default refspec, the built-in git server shall expose the nice/synced branches under `refs/heads/*`; raw workspace refs under `refs/catnip/*` require an explicit refspec.
- R15 (State-driven): While the git server is running, the catnip binary shall serve a clone URL of the form `http://localhost:6369/<repo>.git`.

### Claude / agent session orchestration

- R16 (Ubiquitous): The catnip binary shall allow multiple Claude sessions to run concurrently, keyed per workspace, each bound to its own worktree directory.
- R17 (Event-driven): When a Claude session is detected running in a workspace, the catnip binary shall bind checkpointing, title extraction, and todo monitoring to that workspace. (The full workspace lifecycle applies only to the `claude` agent.)
- R17a (Event-driven): When a user resumes a prior session, the catnip binary shall reattach to the previous Claude session via `--resume`/`--continue`.
- R17b (State-driven): While a Claude session targets an external (non-worktree) directory, the catnip binary shall run it read-only until the user promotes it to writable.
- R17c (Event-driven): When no live process is found for a session, the catnip binary shall mark that session ended.
- R18 (Ubiquitous): The web UI shall present all workspaces, grouped by repository, in an organized sidebar.

### Terminals & remote access

- R20 (Ubiquitous): The catnip binary shall let a user open a full interactive terminal to any workspace via the web UI, the CLI, or SSH.
- R21 (State-driven): While SSH is enabled (the default), the catnip binary shall configure a `catnip_remote` key pair and a `catnip` SSH host (127.0.0.1:2222) so that `ssh catnip` and Remote-SSH clients can connect.
- R21a (If-then): If the `ssh` binary is unavailable or key setup fails, then the catnip binary shall disable SSH automatically rather than aborting startup.
- R22 (Event-driven): When `catnip run` is invoked with `--disable-ssh`, the catnip binary shall not configure SSH.
- R23 (Event-driven): When a user opens a session from a mobile device (viewport ≤768px), the web UI shall render a mobile-optimized prompt/terminal view.

### Port detection, forwarding & proxy

- R24 (Event-driven): When a service starts listening on a port inside the container, the catnip binary shall detect that port (by scanning TCP listen state and terminal output) and forward it to the host over an SSH tunnel at `http://localhost:$PORT`.
- R24a (Ubiquitous): The catnip binary shall not forward privileged ports (<1024), its own port 6369, or the SSH port 22.
- R25 (Ubiquitous): The catnip binary shall set a `PORT` environment variable to a known free port for each workspace.
- R26 (State-driven): While a forwarded service is classified as HTTP, the catnip binary shall make it reachable through the UI proxy at `http://localhost:6369/$PORT`; non-HTTP services are not proxied.
- R27 (If-then, unwanted): If a detected port is not bindable on the host, then the catnip binary shall bind the first available port instead and notify the user of the actual port in the UI.

### Cloudflare worker & codespace proxy (catnip.run)

- R28 (Event-driven): When a Catnip instance boots inside a GitHub Codespace, the `update-codespace` command shall register the codespace name, repository, and a GitHub token with the catnip.run service.
- R28a (Event-driven): When a registration request is received, the worker shall validate that the supplied token belongs to the claimed user (via `GET /user` login match) before storing the record.
- R29 (Event-driven): When a user authenticates at catnip.run and targets a registered codespace, the worker shall, using the user's OAuth token, start the codespace if it is not Available, then redirect to `https://<codespace>-6369.app.github.dev?catnip=true`.
- R30 (Ubiquitous): The worker shall store, encrypted, the GitHub token plus user, codespace name, and repository; the stored token is reused as a health-check token for probing the codespace's Catnip interface.
- R31 (Ubiquitous): The worker shall encrypt stored credentials with AES-GCM (256-bit, per-record salt and IV, versioned keys).
- R32 (Event-driven, on-access): When a stored credential record is read and its `updatedAt` is older than 24 hours, the worker shall null out the encrypted credential fields while retaining the non-secret record. Pruning is lazy/on-read — there is no scheduled job, so records that are never read are not pruned.

### iOS app

- R33 (Where, iOS app): Where the W&B Catnip iOS app is used, it shall guide the user through configuring an existing GitHub repository with Catnip.
- R34 (Where, iOS app): Where the W&B Catnip iOS app is used, it shall let the user interact with a running Claude Code terminal on the device.

### Resilience

- R35 (Event-driven): When the catnip binary restarts, it shall recover its record of existing workspaces and sessions rather than orphaning them.

## Implementation Decisions

The product is composed of these modules. The deep modules (simple, stable interface hiding substantial behavior; independently testable) are flagged.

**Frontend (`src/`)** — React + TypeScript SPA (Vite, ShadCN UI, Tailwind, TanStack Router). Organized into `components`, `routes`, `hooks`, `lib`, `stores`, `types`. Talks to the catnip binary over HTTP/JSONRPC and websockets. Tooltip usage must go through `TooltipPrimitive.Provider/.Root` (never mount `TooltipPrimitive` directly).

**Container backend (`container/`)** — single Go binary. Internal packages: `services`, `git`, `handlers`, `claude`, `config`, `models`, `tui`, `recovery`, `macos`, `assets`, `logger`. The web SPA is embedded in the binary. Key services and their roles:

- **git / worktree management** (`git.go`, `worktree_cache.go`, `worktree_state_manager.go`, `local_repo_manager.go`) — _deep module_. Encapsulates worktree creation, the workspace ref ↔ synced-branch relationship, and worktree caching behind a narrow interface.
- **commit & branch sync** (`commit_sync.go`, `sync_manager.go`) — _deep module_. Owns the checkpoint-commit to `refs/catnip/<catname>`, the lazy nice-branch graduation, and the bidirectional `syncToNiceBranch`/`syncFromNiceBranch` invariants.
- **git server** (`git_http.go`) — serves repo/worktree branches over HTTP for host `clone`/`fetch`.
- **Claude session orchestration** (`claude.go`, `claude_monitor.go`, `claude_parser.go`, `claude_subprocess.go`, `claude_process_registry.go`, `session.go`, `pty.go`) — manages agent subprocess lifecycle, PTY, output parsing, and a process registry. The **claude parser** is a _deep module_ (pure transform from agent output to structured events).
- **port allocation & monitoring** (`port_allocation.go`, `port_monitor.go`) — _deep module_. Detects listening ports, allocates free host ports, drives forwarding/proxy and the `PORT` env var.
- **container runtime** (`container.go`) — abstracts Docker vs Apple Container SDK behind one interface.
- **PR sync** (`pr_sync_manager.go`) — maps workspaces to PR-ready branches.
- **codespace registration** (`cmd/update-codespace.go`) — registers the instance (token, codespace name, repository) with catnip.run on boot.
- **recovery** (`recovery/`) — restores workspace/session state after restart.

**Worker (`worker/`)** — Cloudflare Worker (Hono) hosting the production edge and the codespace proxy/store (`codespace-store.ts`). Holds AES-GCM-encrypted codespace credentials, pruned lazily on read after 24h (no scheduled cron).

**iOS app (`xcode/`)** — native Swift app (App Store: "W&B Catnip"). Build checks via `just build` / `just build-quick` from the `xcode/` directory.

**Contracts & conventions** (unchanged by this PRD, recorded for grounding):

- Workspace ref scheme: `refs/catnip/<catname>` (random cat name), graduating to a semantic nice branch once a session is titled; a `catnip/<catname>` preview branch exposes uncommitted work.
- Default port: `6369` (C-A-T-S); UI proxy path: `/$PORT`.
- Host git remote name: `catnip`.
- Devcontainer feature: `ghcr.io/wandb/catnip/feature:1`.
- Per-workspace `setup.sh` runs at creation; `-e` and `CATNIP_*_VERSION` configure the container.

## Testing Decisions

A good test here verifies **external behavior**, not implementation details — e.g. "auto-commit produces a commit on the workspace ref and advances the synced branch" rather than asserting on private helpers. The deep modules above are the natural isolation-test boundaries, and several already have substantial coverage that serves as prior art:

- **git / worktree & branch sync** — `git_test.go`, `git_functional_test.go`, `git_inmemory_test.go`, `branch_sync_test.go`, `commit_sync_test.go`. The in-memory git tests are good prior art for exercising worktree/ref behavior without a real container.
- **port allocation** — `port_allocation_test.go` (allocate-free-port and fallback-on-conflict behavior, covering R24–R27).
- **claude session parsing/monitoring** — `claude_parser_test.go`, `claude_monitor_test.go`, `claude_subprocess_test.go` (with `claude_subprocess_mock.go`), `claude_onboarding_test.go`, `capture_oauth_test.go`.
- **container runtime** — `container_test.go`.
- **session lifecycle** — `session_test.go`.
- See `container/internal/services/TESTING.md` for the existing testing approach and `test_helpers.go` / `testing_utils.go` for shared fixtures.

Frontend behavior is validated with vitest (`pnpm test`) and colocated `*.test.ts(x)`; end-to-end flows via `pnpm dev` / `pnpm dev:cf`. Keep tests fast, isolated, and mock external dependencies. Run `pnpm typecheck` and `pnpm lint` before committing; run `just build` in `container/` for Go changes.

## Out of Scope

- Designing new features or behavior changes — this PRD documents the **current** product state only.
- Multi-agent support beyond Claude Code (roadmap item "more AI coding agents"). Today the workspace lifecycle (checkpointing, titles, read-only mode) is gated to the `claude` agent. Pi is the intended next adapter target; Gemini/Google provider support is not planned for the near or medium term. Treat first-class non-Claude agents as future work, not current behavior.
- Non-GitHub cloud environments ("other cloud native environment" roadmap item).
- Billing, licensing, and account management for catnip.run.
- Internal implementation details, file-by-file APIs, and code snippets (intentionally omitted so the PRD doesn't rot).

## Further Notes

- This PRD was synthesized from the repository (README, AGENTS.md, docs/, and the `container/internal` + `src/` module layout), not from new product discovery. It supersedes the informal `SUMMARY.md` as the structured reference.
- Requirements use EARS per the standing convention recorded in beads memory `convention-favor-ears-easy-approach-to-requirements-syntax`.
- Catnip is dogfooded on itself ("Inception") — `catnip run --dev` from within this repo is the contributor dev loop.
- ADR-0001 records that issue tracking lives in embedded **beads**, which is why work is tracked in `bd` rather than GitHub Issues.
