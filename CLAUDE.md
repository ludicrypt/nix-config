# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal macOS configuration managed declaratively with [Lix](https://lix.systems), [nix-darwin](https://github.com/LnL7/nix-darwin), [home-manager](https://github.com/nix-community/home-manager), and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew). Config is split by topic into `modules/{darwin,home}/`; all machine- and user-specific values live in a single `host.nix`.

## File roles

- **`host.nix`** — host-specific values (username, hostname, system, git identity, repo URLs). The single source of truth — and the only file you edit to fork this config for a new machine.
- **`flake.nix`** — inputs (nixpkgs, nix-darwin, home-manager, nix-homebrew), outputs, and module wiring. Imports `./host.nix` and threads the resulting `host` set through specialArgs to every module. Also exposes `host` as a flake output so tooling (e.g. `bootstrap.sh`) can read values via `nix eval --raw .#host.hostname`.
- **`modules/darwin/system.nix`** — system services (SSH/Screen Sharing daemons, pmset, restart-after-freeze), system.defaults for NSGlobalDomain/finder/trackpad, hostname (three flavors), Rosetta install, Touch ID for sudo, nix experimental-features.
- **`modules/darwin/homebrew.nix`** — Homebrew casks/brews/masApps and `system.defaults.dock` (co-located because `dock.persistent-apps` references cask install paths).
- **`modules/home/shell.nix`** — zsh, starship, fzf, zoxide, direnv, aliases, `home.stateVersion`.
- **`modules/home/git.nix`** — `programs.git` (with `host.git.name`/`host.git.email`), delta, lazygit, SSH config, key generation + allowed_signers.
- **`modules/home/editor.nix`** — neovim package, AstroNvim bootstrap activation, the mutable `nvim/lua` symlink.
- **`modules/home/terminal.nix`** — Ghostty config + shaders, JetBrainsMono Nerd Font, `programs.tmux`.
- **`modules/home/dev.nix`** — `programs.gh`, language runtimes (uv, pixi, nodejs, bun, fnm).
- **`modules/home/cli.nix`** — `programs.bat`, `programs.htop`, ripgrep/fd/eza/jq/yq/tree/wget/httpie/btop/lazydocker.
- **`modules/home/bootstrap.nix`** — `home.activation` entries that install Claude Code / OpenCode / Codex (self-updating CLIs Nix can't sanely manage), and `home.sessionPath` for their binaries.

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
| CLI tools (nixpkgs) | `home.packages` in `modules/home/cli.nix` (general) or `modules/home/dev.nix` (language runtimes & dev CLIs) |
| GUI apps (.app bundles) | `homebrew.casks` in `modules/darwin/homebrew.nix` |
| Mac App Store apps | `homebrew.masApps` in `modules/darwin/homebrew.nix` |
| Dock pinned apps | `system.defaults.dock.persistent-apps` in `modules/darwin/homebrew.nix` (co-located with casks) |
| macOS preferences (non-dock) | `system.defaults` in `modules/darwin/system.nix` |
| Shell aliases / env | `programs.zsh` in `modules/home/shell.nix` |
| PATH additions | `home.sessionPath` in `modules/home/bootstrap.nix` |
| Git config | `programs.git.settings` in `modules/home/git.nix` (uses `host.git.*`) |
| Per-machine values (username, hostname, system, git identity) | `host.nix` |

Prefer nixpkgs over Homebrew for CLI tools. Use casks only for `.app` bundles. Convert bare `home.packages` entries to their `programs.*` form when home-manager has one (e.g. `programs.bat`, `programs.tmux`, `programs.gh`, `programs.lazygit`, `programs.htop`) — that gets you declarative config + completions + integrations for free.

## Architecture notes

- **`host` specialArg.** Every module receives `host` (from `./host.nix`) via specialArgs. Reference `host.username`, `host.hostname`, `host.system`, `host.git.{name,email}`, `host.repo.{url,sshUrl}` instead of hardcoding.
- **Claude Code / OpenCode / Codex** are intentionally not managed by Nix — their installers self-update the binaries. `modules/home/bootstrap.nix` runs the installers once via `home.activation` entries if the binaries are absent, then they auto-update in the background. These are `home.activation` (not `system.activationScripts`) so they run as the user natively, no `sudo -H -u` gymnastics.
- **Activation scripts in `modules/darwin/system.nix`** must use the hook names nix-darwin actually invokes (`preActivation`, `postActivation`, `extraActivation`). Custom-named entries like `system.activationScripts.myThing` are silently ignored.
- **`sudo -H -u ${host.username}`** is still required in any *darwin* activation script that writes to the user's home (e.g. the trackpad `defaults write`) — without `-H`, `$HOME` stays as `/var/root`. *home-manager* activation scripts already run as the user, so no sudo needed.
- **`system.primaryUser`** must be set whenever `homebrew.*` or `system.defaults.*` are used. Set in `modules/darwin/system.nix` to `host.username`.
- **`home-manager.backupFileExtension = "hm-backup"`** is set in `flake.nix`. When a pre-existing file outside home-manager's control (e.g. a manual `gh auth login` writing `~/.config/gh/config.yml`) collides with a declarative file, home-manager backs it up to `foo.hm-backup` instead of halting activation. Check for and delete stale `*.hm-backup` files when sure the originals aren't needed.

## Gotchas

- `darwin-rebuild switch` requires `sudo` as of mid-2025.
- Touch ID for sudo only works after the first successful switch that installs the PAM config.
- First build is slow (downloads everything); subsequent rebuilds are usually seconds to a minute.
- Hostname auto-detection uses the Mac's current `HostName`, which on a fresh Mac is still the default name. The first build needs an explicit `--flake .#hostname`.
- Don't use `nix profile install` for permanent packages — put them in the flake instead.
