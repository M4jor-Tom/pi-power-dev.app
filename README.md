# pi-power-dev.app

Runs the [pi](https://pi.dev) coding agent against the
[`pi-power-dev`](https://github.com/M4jor-Tom/pi-power-dev) profile, and
supplies every CLI that profile's skills shell out to.

```bash
nix run github:M4jor-Tom/pi-power-dev.app
```

On first run it clones the profile to `~/.pi-power-dev`. On later runs it
fast-forwards that clone, but only when the tree is clean — local edits are
never clobbered. Override the location with `PI_POWER_DEV_DIR`.

This app is a convenience, not a requirement. The profile works on its own:

```bash
PI_CODING_AGENT_DIR=~/.pi-power-dev pi
```

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
