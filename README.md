# pi-power-dev.app

Runs the [pi](https://pi.dev) coding agent against the
[`pi-power-dev`](https://github.com/M4jor-Tom/pi-power-dev) profile, and
supplies every CLI that profile's skills shell out to.

```bash
nix run github:M4jor-Tom/pi-power-dev.app
```

On first run it clones the profile to `~/.pi-power-dev`. On later runs it
fast-forwards that clone, but only when the tree is clean — local edits are
never clobbered — and only when `origin` still points at this profile's own
repo, so pointing `PI_POWER_DEV_DIR` at a fork or an unrelated checkout gets
no pulls. Override the location with `PI_POWER_DEV_DIR`.

This app is a convenience, not a requirement. The profile works on its own:

```bash
PI_CODING_AGENT_DIR=~/.pi-power-dev pi
```

## Local models with Ollama

The default `nix run .` and `nix run .#pi-power-dev` do not start or configure
Ollama. Two opt-in apps each need just one terminal:

```bash
nix run .#ollama                          # choose “Chat with a model” in the menu
nix run .#ollama -- pull qwen2.5:3b        # or download an exact tag and exit
nix run .#pi-with-ollama                   # open Pi; choose pi-ollama in /model
```

Each starts a background Ollama server on its own loopback port and stops it
when the foreground app closes. Neither connects to or stops a system Ollama.
Model downloads persist. If you download a model while Pi is open, use `/reload`
then `/model`. The launcher adds a provider but doesn't change your Pi default.
For a private document, explicitly select the local model before entering text:

```bash
nix run .#pi-with-ollama -- --model pi-ollama/qwen2.5:3b --no-session
```

Ollama uses its normal `~/.ollama/models` store. If another installation uses
a different directory (the NixOS service normally uses `/var/lib/ollama/models`),
set `OLLAMA_MODELS` to that directory **when launching either app** and ensure
your user has access. No models are copied; removing a shared model affects both
installations. Avoid concurrent pulls or deletes against the same store.

## What it ships

`pi-coding-agent git gh glab nodejs bun ripgrep fd jq yq-go uv python3 rtk
graphify markitdown pandoc poppler-utils yt-dlp`

`nixpkgs#pi-coding-agent` already sets `PI_SKIP_VERSION_CHECK=1` and
`PI_TELEMETRY=0` and provides `rg`/`fd` to pi itself.

Two dependencies are deliberately absent. `playwright-driver` is not shipped
because the `playwright-cli` skill installs `@playwright/cli` through npm and
manages its own browsers. `graphify` is shipped at the nixpkgs version
(0.4.23) even though the skill pins 0.8.30 — `uv` is shipped alongside so the
skill's own `uv tool install --upgrade graphifyy` path can take over.
