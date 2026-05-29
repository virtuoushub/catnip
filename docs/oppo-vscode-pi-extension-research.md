# Opportunity Research: Simple VS Code Extension for pi

Date: 2026-05-29

Goal: assess whether projects already exist like [`ravshansbox/vscode-pi-companion`](https://github.com/ravshansbox/vscode-pi-companion), using a red/blue team lens, and identify a viable path for a simple VS Code extension for pi.

## Summary

There are already several VS Code integrations for pi. The space is not empty. The strongest existing project appears to be [`pithings/pi-vscode`](https://github.com/pithings/pi-vscode), which already covers much of the obvious MVP: terminal launcher, VS Code bridge, live status, selection/open-editor/diagnostics tools, `@pi` chat participant, and package management.

A simple new extension is still viable if it avoids trying to become “Cursor for pi.” The best opening is a small, auditable, terminal-first extension with explicit context sharing and privacy-preserving defaults.

Recommended positioning:

> **pi-vscode-minimal**: one-command pi terminal integration with explicit VS Code context sharing. No webview. No hidden prompt injection. No magic.

## Competitive Map

| Project                                                                                                 |                                                                                                                                         Position |                     Threat Level |
| ------------------------------------------------------------------------------------------------------- | -----------------------------------------------------------------------------------------------------------------------------------------------: | -------------------------------: |
| [`pithings/pi-vscode`](https://github.com/pithings/pi-vscode)                                           | Best current “simple but polished” pi VS Code extension: terminal launcher, bridge, status, selections, diagnostics, `@pi` chat, package manager |                         **High** |
| [`ravshansbox/vscode-pi-companion`](https://github.com/ravshansbox/vscode-pi-companion)                 |                                            Real-time IDE context bridge: VS Code server + pi extension, SSE updates, tools for active/open files | **High for context-bridge idea** |
| [`Zetaphor/pi-vscode-extension`](https://github.com/Zetaphor/pi-vscode-extension)                       |                                                            Full native sidebar chat UI, tool cards, checkpoints, diffs, settings, Cursor-like UX |                      Medium/high |
| [`gnassro/phi`](https://github.com/gnassro/phi)                                                         |                                                          Native VS Code chat extension using pi SDK, tool cards, thinking blocks, editor context |                           Medium |
| [`tintinweb/vscode-pi-model-chat-provider`](https://github.com/tintinweb/vscode-pi-model-chat-provider) |                                                     VS Code Language Model Provider exposing pi models to Copilot Chat / `vscode.lm.*` consumers |                           Medium |
| [`twcrews/crust`](https://github.com/twcrews/crust)                                                     |                                                                                          Chat UI + session browser + IDE context + terminal mode |                           Medium |
| [`wiinnie-the-pooh/terminal-pi`](https://github.com/wiinnie-the-pooh/terminal-pi)                       |                                                                            Terminal-first VS Code docking / resource launching / session restore |                       Low/medium |
| `pi-vscode-lite`, `rubens-fidelis/pi-vscode`, etc.                                                      |                                                                                                                 Smaller terminal/context bridges |                              Low |

## Red Team: Why This May Fail

### 1. `pithings/pi-vscode` already owns the obvious MVP

It already provides:

- Marketplace + Open VSX distribution
- Terminal launch
- VS Code bridge
- Selection/open editor/diagnostics awareness
- `@pi` chat participant
- pi package manager UI
- Token-authenticated local bridge

A new project that simply says “open pi in VS Code and send selected text” will look like a weaker clone unless it has sharper positioning.

### 2. Full chat UI is a trap

Several projects are already trying to build a native chat interface. This path has a large maintenance surface:

- Streaming responses
- Tool cards
- Diffs
- Checkpoints
- Sessions
- Model picker
- Rollback
- Settings
- Auth
- Prompt queueing and steering

A small project should avoid rebuilding pi’s TUI poorly.

### 3. Auto context injection is risky

`vscode-pi-companion` injects selected/current file context before agent start. This is convenient, but it can also:

- Surprise users
- Leak private code
- Waste tokens
- Pollute prompts
- Make agent behavior harder to reason about

A privacy-conscious user may prefer explicit “send selection” over invisible context.

### 4. Two-sided install friction

A proper bridge often needs both:

- A VS Code extension
- A pi extension loaded via `--extension` or `pi install`

If setup is not one-click, users bounce. A good implementation should bundle the pi bridge extension inside the VS Code extension and pass it to pi automatically.

### 5. Security footguns

Local bridge risks:

- Local HTTP endpoints must bind only to `127.0.0.1`
- Every endpoint should require a random token
- Avoid unauthenticated `/context` or `/stream` endpoints, even on localhost
- Avoid silently installing extensions from inside pi
- Avoid sending file contents unless explicitly requested

### 6. Version churn

Some existing repos still reference older package names such as `@mariozechner/pi-coding-agent`. Current docs use `@earendil-works/pi-coding-agent` and `typebox`.

A simple extension should avoid depending deeply on unstable internals.

## Blue Team: Viable Opening

Do not compete as “best pi IDE.” Compete as:

> “The tiny, auditable VS Code bridge for people who still want pi’s terminal UX.”

### MVP Feature Set

1. **Open/focus pi terminal**
   - Status bar button: `π Pi`
   - Command: `Pi: Open`
   - Launches `pi` in integrated terminal
   - Passes a bundled pi bridge extension with `--extension`

2. **Send selection to pi**
   - Command: `Pi: Send Selection`
   - Right-click menu
   - Optional keybinding
   - Sends explicit prompt text, not hidden context

3. **Open with file context**
   - Command: `Pi: Open with Current File`
   - Adds file path + cursor/selection range to initial prompt or system appendix

4. **Minimal VS Code bridge tools**
   - `vscode_get_selection`
   - `vscode_get_active_file`
   - `vscode_get_open_editors`
   - `vscode_get_diagnostics`

5. **Privacy defaults**
   - No automatic file content injection
   - No background sending selected text unless user invokes command
   - Authenticated local bridge only
   - Clear status: “VS Code bridge connected”

## Recommended Architecture

Use the `pithings/pi-vscode` pattern, simplified:

```text
VS Code extension
  ├─ starts local HTTP bridge on 127.0.0.1
  ├─ creates random token
  ├─ launches pi terminal:
  │    pi --extension <bundled-pi-bridge.js>
  └─ passes env:
       PI_VSCODE_BRIDGE_URL=http://127.0.0.1:<port>
       PI_VSCODE_BRIDGE_TOKEN=<token>

pi bridge extension
  ├─ reads env vars
  ├─ registers pi tools
  ├─ calls VS Code bridge with token
  └─ optionally sets pi widget/status
```

Use **RPC mode only if building a native chat UI**. For a simple VS Code extension, terminal-first is easier and more differentiated.

## Specific Improvements Over `vscode-pi-companion`

- Authenticate all endpoints, not just MCP
- No automatic hidden context injection by default
- Use current `@earendil-works/pi-coding-agent` docs/package names
- Do not auto-install VS Code extension from pi
- Keep bridge protocol tiny
- Ship one extension: VS Code extension bundles the pi bridge file

## Verdict

There are definitely other projects. The strongest competitor is **`pithings/pi-vscode`**. If the goal is a simple extension, the best chance is **not feature breadth** but **trust + minimalism**:

> explicit context, terminal-first, auditable bridge, no webview, no hidden injection.

## Next Steps

1. Decide whether this is a terminal-first extension or a native chat UI. Recommendation: terminal-first.
2. Scaffold a VS Code extension with:
   - status bar item
   - command registration
   - terminal launcher
   - local token-authenticated bridge
   - bundled pi bridge extension
3. Implement only four bridge tools initially:
   - get active file
   - get selection
   - list open editors
   - get diagnostics
4. Add a clear privacy section to the README.
5. Avoid auto-injection until users explicitly ask for it.
