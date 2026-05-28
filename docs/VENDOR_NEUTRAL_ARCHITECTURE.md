# Catnap Vendor-Neutral Architecture

Catnap is the temporary codename for a Catnip-derived agent workspace manager whose core value survives changes in AI providers, code hosts, cloud runtimes, and corporate sponsors.

This document is a north-star architecture, not a migration checklist. It records the desired shape: a local-first core surrounded by explicit adapters.

## Design goals

- Keep the **local core** useful without any hosted service.
- Treat AI agents, code hosts, relays, identity providers, and storage backends as adapters.
- Preserve Catnip's strongest idea: isolated git-backed workspaces for parallel coding agents.
- Prefer FOSS, community-led, or non-profit infrastructure where practical.
- Allow proprietary integrations only when they are optional and replaceable.

## Non-negotiable independence boundaries

Catnap core must not require:

- W&B or CoreWeave services
- Anthropic or Claude Code
- GitHub or Codespaces
- Cloudflare
- Apple Container SDK
- A proprietary mobile app store path

These can exist as adapters. They must not be the only path.

## Current risk map

```mermaid
flowchart TD
  User[Developer / mobile user]
  UI[Web UI]
  Core[Catnip local Go core]
  Agent[Claude Code]
  Host[GitHub / Codespaces]
  Hosted[catnip.run on Cloudflare]
  Mobile[iOS app]
  Git[Local git worktrees + refs]

  User --> UI
  UI --> Core
  Core --> Git
  Core --> Agent
  Core --> Host
  Mobile --> Hosted
  Hosted --> Host
  Core -. optional convenience .-> Hosted

  classDef risk fill:#fee2e2,stroke:#dc2626,color:#111;
  classDef core fill:#dcfce7,stroke:#16a34a,color:#111;
  class Agent,Host,Hosted,Mobile risk;
  class Core,Git core;
```

Key observation from architecture review: local `catnip run` is not load-bearing on `catnip.run`. If hosted services disappear, the local product continues. The blast radius is mainly mobile and Codespaces convenience.

## Target architecture

```mermaid
flowchart TB
  subgraph LocalCore[Local-first Catnap core]
    UI[Web UI]
    API[HTTP / JSONRPC / WebSocket API]
    Workspace[Workspace manager]
    GitState[Git state model\nworktrees / refs / checkpoints]
    Terminal[PTY + terminal sessions]
    Ports[Port detector + preview proxy]
    Secrets[Env + secrets injection]
  end

  UI --> API
  API --> Workspace
  Workspace --> GitState
  Workspace --> Terminal
  Workspace --> Ports
  Workspace --> Secrets

  Workspace --> AgentRunner{{AgentRunner adapter}}
  GitState --> GitHost{{GitHost adapter}}
  API --> Relay{{Remote relay adapter}}
  API --> HostedBackend{{Hosted backend adapter}}
  Workspace --> Runtime{{Container runtime adapter}}
  API --> IssueTracker{{Issue tracker adapter}}

  AgentRunner -.-> Claude[Claude Code compatibility]
  AgentRunner -.-> Pi[pi-native]
  AgentRunner -.-> Codex[Codex CLI candidate]

  GitHost -.-> Forgejo[Forgejo / Codeberg]
  GitHost -.-> GitHub[GitHub legacy]
  GitHost -.-> Generic[Generic Git]

  Relay -.-> SSH[Direct SSH]
  Relay -.-> WireGuard[WireGuard / headscale]
  Relay -.-> ReverseSSH[Reverse SSH]
  Relay -.-> Codespaces[Codespaces legacy]

  HostedBackend -.-> SelfHost[Postgres + MinIO]
  HostedBackend -.-> Cloudflare[Cloudflare legacy]

  Runtime -.-> OCI[OCI / Podman / Docker]
  Runtime -.-> Apple[Apple Container SDK]

  IssueTracker -.-> Beads[beads]
  IssueTracker -.-> Absurd[absurd candidate]
```

## Trust boundaries

```mermaid
flowchart LR
  subgraph TrustedLocal[Trusted local boundary]
    Core[Catnap core]
    Repo[Mounted repo]
    Worktrees[Agent worktrees]
    LocalGit[Local git refs]
  end

  subgraph OptionalRemote[Optional remote convenience]
    Relay[Relay / wake / route]
    HostedStore[Hosted session metadata]
    Mobile[Mobile client]
  end

  subgraph ExternalVendors[External services]
    AI[AI provider]
    Forge[Code host]
    Cloud[Cloud runtime]
  end

  Core --> Repo
  Core --> Worktrees
  Core --> LocalGit
  Core -. encrypted / authenticated route .-> Relay
  Mobile -.-> Relay
  Relay -. no workspace ownership .-> Core
  Core -. adapter .-> AI
  Core -. adapter .-> Forge
  Core -. adapter .-> Cloud
```

Rule: remote convenience layers route, wake, and observe. They do not own workspace state.

## Adapter priorities

| Seam                            | Priority | Status          | Why                                                                                                                                      |
| ------------------------------- | -------: | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `AgentRunner`                   |        1 | Strong          | Claude plus the intended Pi adapter imply multiple agents. This directly de-risks Anthropic coupling without depending on Google/Gemini. |
| `AgentMessage` / `AgentSession` |        1 | Strong          | Claude-shaped events and fields leak into UI consumers. Pair with `AgentRunner` to avoid double churn.                                   |
| `GitHost`                       |        2 | Worth exploring | GitHub assumptions exist, but only one host is real today. Build seam with Forgejo/Codeberg adapter, not before.                         |
| `HostedBackend`                 |        3 | Worth exploring | Cloudflare/catnip.run affects convenience tier. Local core survives. Early cheap win: configurable mobile base URL.                      |
| `IssueTracker`                  |        3 | Low-risk        | beads remains default; absurd can be explored as adapter.                                                                                |

## Agent session contract

Catnap should abstract agent session lifecycle, not invent a universal LLM API.

Core owns:

- workspace allocation
- environment and secrets injection
- PTY/process lifecycle
- transcript and event capture
- checkpoint triggers
- title/task extraction contract
- permission and sandbox policy

Agent adapters own:

- executable or SDK invocation
- resume/continue semantics
- auth flow and OAuth capture
- output parsing into common events

Initial target adapters:

1. Claude Code compatibility adapter, preserving existing behavior.
2. pi-native adapter, preferred for long-term provider flexibility.
3. Codex CLI candidate adapter after the session contract stabilizes.

pi is an adapter, not a core dependency.

## Git and forge contract

Core git behavior stays forge-neutral:

- worktree creation
- workspace refs
- checkpoint commits
- branch synchronization
- built-in git server
- clone/fetch/push primitives

Forge adapters own optional features:

- PR/MR creation
- repo discovery
- OAuth/device auth
- Codespace/dev-environment wakeups
- provider-specific URL parsing

Default direction: Forgejo/Codeberg first, GitHub legacy supported, Generic Git always available.

## Remote access contract

Catnap is local-first with optional relays.

```mermaid
sequenceDiagram
  participant User
  participant MobileOrBrowser as Mobile / browser
  participant Relay as Optional relay adapter
  participant Core as Local Catnap core
  participant Workspace as Workspace PTY

  User->>MobileOrBrowser: open session
  MobileOrBrowser->>Relay: request route / wake
  Relay->>Core: authenticated encrypted connection
  Core->>Workspace: attach PTY
  Workspace-->>Core: terminal stream
  Core-->>Relay: stream frames
  Relay-->>MobileOrBrowser: stream frames
```

Relay constraint: no relay should be required for localhost or direct SSH use.

## Provisional default ecosystem

These defaults are directional and need deeper design per line item.

| Area           | Provisional default                        | Other adapters                                      |
| -------------- | ------------------------------------------ | --------------------------------------------------- |
| Code host      | Forgejo / Codeberg                         | GitHub, GitLab CE, Generic Git                      |
| Issue tracker  | beads                                      | absurd candidate                                    |
| Runtime        | OCI-compatible runtime, Podman first-class | Docker, Apple Container SDK                         |
| Remote access  | Direct SSH / self-hosted tunnel            | WireGuard/headscale, reverse SSH, Codespaces legacy |
| CI             | Forgejo Actions or Woodpecker              | GitHub Actions adapter                              |
| Hosted backend | Self-hosted Postgres + MinIO               | Cloudflare legacy                                   |
| Decisions      | ADRs/RFCs in repo                          | none                                                |

## Migration priority flow

```mermaid
flowchart TD
  A[Stabilize language\nCatnap docs + glossary] --> B[Extract AgentRunner]
  B --> C[Introduce AgentMessage / AgentSession]
  C --> D[Add pi-native adapter]
  D --> E[Build Forgejo/Codeberg GitHost with seam]
  E --> F[Make mobile / hosted base URL configurable]
  F --> G[Evaluate self-hosted HostedBackend]
  G --> H[Deep-dive ecosystem defaults]
```

## Open design questions

- What is the minimum `AgentRunner` interface that supports Claude Code and pi without overfitting either?
- What common `AgentMessage` shape preserves rich tool output without turning into a lowest-common-denominator blob?
- Which Forgejo/Codeberg flows matter first: clone, auth, PR/MR creation, or remote workspace wakeup?
- Should hosted convenience be one deployable service or several small optional services?
- What governance body or process owns adapter acceptance and default changes?
