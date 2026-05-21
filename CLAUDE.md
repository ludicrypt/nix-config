# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal macOS configuration managed declaratively with [Lix](https://lix.systems), [nix-darwin](https://github.com/LnL7/nix-darwin), [home-manager](https://github.com/nix-community/home-manager), and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew). Three files describe the entire machine state.

## File roles

- **`flake.nix`** — inputs (nixpkgs, nix-darwin, home-manager, nix-homebrew), outputs, and module wiring. Contains the `username`, `hostname`, and `system` variables at the top of the `let` block.
- **`darwin.nix`** — system-level config: Homebrew casks/brews/masApps, macOS `system.defaults`, activation scripts, hostname, Touch ID for sudo.
- **`home.nix`** — user-level config: `home.packages` (CLI tools from nixpkgs), shell (zsh + starship + fzf + zoxide), git settings, shell aliases.

## Key commands

```bash
# Apply config changes (requires sudo as of mid-2025)
sudo darwin-rebuild switch --flake ~/.config/nix-config

# Undo the last switch
sudo darwin-rebuild switch --rollback

# First build on a fresh Mac (before hostname is set)
sudo nix run nix-darwin -- switch --flake .#thegibson04

# Bump all pinned flake inputs to latest
nix flake update

# Find a package
nix search nixpkgs <name>

# Try a package without installing
nix shell nixpkgs#<name>

# Find a Mac App Store app ID
mas search "<App Name>"
```

**Always `git add` new files before rebuilding.** Nix flakes only see git-tracked files; untracked files are invisible and the build will fail silently.

## Where things go

| What | Where |
|------|-------|
| CLI tools (nixpkgs) | `home.packages` in `home.nix` |
| GUI apps (.app bundles) | `homebrew.casks` in `darwin.nix` |
| Mac App Store apps | `homebrew.masApps` in `darwin.nix` |
| macOS preferences | `system.defaults` in `darwin.nix` |
| Shell aliases / env | `programs.zsh` in `home.nix` |
| PATH additions | `home.sessionPath` in `home.nix` |

Prefer nixpkgs over Homebrew for CLI tools. Use casks only for `.app` bundles.

## Architecture notes

- **Claude Code** is intentionally not managed by Nix — Anthropic's native installer runs once via `system.activationScripts.postActivation` in `darwin.nix`, then the binary self-updates. `~/.local/bin` is added to `home.sessionPath` so the binary is found.
- **Activation scripts** must use the hook names nix-darwin actually invokes (`preActivation`, `postActivation`, `extraActivation`). Custom-named entries like `system.activationScripts.myThing` are silently ignored.
- **`sudo -H -u ${username}`** is required in activation scripts that write to the user's home — without `-H`, `$HOME` stays as `/var/root`.
- **`system.primaryUser`** must be set whenever `homebrew.*` or `system.defaults.*` are used, so the root-run activation knows which user's preferences to apply.

## Gotchas

- `darwin-rebuild switch` requires `sudo` as of mid-2025.
- Touch ID for sudo only works after the first successful switch that installs the PAM config.
- First build is slow (downloads everything); subsequent rebuilds are usually seconds to a minute.
- Hostname auto-detection uses the Mac's current `HostName`, which on a fresh Mac is still the default name. The first build needs an explicit `--flake .#hostname`.
- Don't use `nix profile install` for permanent packages — put them in the flake instead.
