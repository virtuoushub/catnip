# 🐾 Catnip — Repository Summary

**Catnip** (by Weights & Biases) is an open-source, agent-friendly development environment designed to **run Claude Code everywhere** — in the cloud, locally, or on mobile.

---

## Core Purpose

Catnip solves the problem of managing multiple AI coding agent sessions by running them in isolated containers with automated git worktree management. It lets you spawn parallel Claude Code sessions, review their changes, and interact with them remotely from a phone or browser.

---

## Architecture

| Layer | Tech | Role |
|---|---|---|
| **Frontend** | React + TypeScript, Vite, ShadCN UI, Tailwind, TanStack Router | Web UI for managing workspaces, terminals, previews |
| **Container/Backend** | Go binary (`catnip`) | CLI, JSONRPC APIs, git server, SSH, port forwarding, container orchestration |
| **Worker** | Cloudflare Worker (Hono) | Production edge logic, codespace proxy at `catnip.run` |
| **Mobile** | iOS native app (Swift/Xcode in `xcode/`) | W&B Catnip on the App Store |

---

## Key Features

- **Isolated sandboxes** — runs in Docker or Apple's Container SDK; `--dangerously-skip-permissions` safe
- **Worktree management** — each Claude session gets its own git worktree, commits to `refs/catnip/$NAME`, auto-synced to a named branch
- **Parallel agents** — spawn many Claude sessions simultaneously, keep them organized
- **Port forwarding** — auto-detects and proxies container ports to the host
- **SSH access** — `ssh catnip` or remote dev via Cursor/VS Code
- **Mobile UI** — interact with the Claude terminal from your phone via `catnip.run`
- **GitHub Codespaces integration** — install as a devcontainer feature, access from anywhere

---

## Directory Highlights

- `src/` — React SPA (components, routes, hooks, stores)
- `container/` — Go binary source, Dockerfile, `just` tasks
- `worker/` — Cloudflare Worker + codespace store logic
- `xcode/` — iOS native app
- `mock-server.js` — mock backend for frontend-only dev (`pnpm dev:mock`)
- `setup.sh` — runs inside each workspace to install project dependencies

---

## Dev Workflow

```bash
pnpm dev          # frontend only
pnpm dev:mock     # frontend with mock backend
just build-dev && just run-dev  # full container + frontend
catnip run --dev  # run from within the catnip repo itself
```

---

**TL;DR:** Catnip is a self-hostable, containerized Claude Code manager with a React web UI, Go backend, Cloudflare worker, and iOS app — built by W&B, developed using itself ("Inception 🤯").
