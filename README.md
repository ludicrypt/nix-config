# nix-config

Personal macOS configuration managed declaratively with [Lix](https://lix.systems), [nix-darwin](https://github.com/LnL7/nix-darwin), [home-manager](https://github.com/nix-community/home-manager), and [Homebrew](https://brew.sh) (controlled by nix-darwin). One `flake.nix` describes the entire machine — CLI tools, GUI apps, App Store apps, dotfiles, shell config, macOS preferences — so a new MacBook can be restored to my exact setup in ~30 minutes.

## What this manages

- **CLI tools** from nixpkgs (ripgrep, fd, bat, eza, jq, fzf, etc.)
- **GUI apps** via Homebrew casks (VS Code Insiders, Ghostty)
- **Mac App Store apps** via `mas` (declared in `darwin.nix`)
- **Shell, git, and tool configs** via home-manager (zsh + starship, git, fzf, zoxide)
- **macOS system defaults** — dock, Finder, keyboard repeat, dark mode, etc.
- **Claude Code** bootstrapped via Anthropic's native installer in a `system.activationScripts` hook (binary self-updates from there)
- **Touch ID for sudo**
- **Hostname** (HostName, LocalHostName, ComputerName)

## Quick start — restoring on a new Mac

After finishing the macOS first-boot wizard (Apple ID, Wi-Fi, etc.), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ludicrypt/nix-config/main/bootstrap.sh)
```

That's it. The script installs Xcode CLT, Lix, clones this repo, and runs the first `nix-darwin` build. It's idempotent — safe to re-run if something fails partway through.

**What it does, step by step:**

1. Checks you're on macOS and not running as root
2. Installs Xcode Command Line Tools if absent (triggers the system dialog)
3. Installs [Lix](https://lix.systems) if no `nix` is found (you'll confirm the install plan)
4. Clones this repo to `~/.config/nix-config` (or pulls if already there)
5. Runs `sudo nix run nix-darwin -- switch --flake .#thegibson04`

Twenty minutes of downloading and the machine matches the source of truth.

## Prerequisites

- macOS 14 (Sonoma) or later, on Apple Silicon or Intel
- Xcode Command Line Tools
- Lix (or upstream Nix or Determinate Nix — Lix is recommended; nix-darwin tests primarily against vanilla, and Lix's error messages are noticeably better than CppNix's)

## Repo structure

```
~/.config/nix-config/
├── flake.nix       # Inputs (nixpkgs, nix-darwin, home-manager, nix-homebrew), outputs, and module wiring
├── darwin.nix      # System-level config: packages, Homebrew, macOS defaults, activation scripts
└── home.nix        # User-level config: dotfiles, shell, programs.* modules from home-manager
```

Once these files grow, split them into `modules/` and import — but flat works fine for a one-machine setup.

## Daily commands

| Command | Purpose |
|---|---|
| `sudo darwin-rebuild switch --flake ~/.config/nix-config` | Apply config changes |
| `sudo darwin-rebuild switch --rollback` | Undo the last switch |
| `darwin-rebuild --list-generations` | See past generations |
| `nix flake update` | Bump all pinned inputs to latest |
| `nix search nixpkgs <name>` | Find a package in nixpkgs |
| `nix shell nixpkgs#<name>` | Open a shell with a package, no install |
| `nix run nixpkgs#<name>` | Run a package once, no install |
| `mas search "<name>"` | Find a Mac App Store app's ID for `homebrew.masApps` |

After editing `darwin.nix` or `home.nix`:

```bash
cd ~/.config/nix-config
git add .                    # Untracked files are invisible to flakes — must `git add` new files
sudo darwin-rebuild switch --flake .
```

## Customizing this for your own use

If you're forking this repo, the things you'll definitely need to change:

1. **`flake.nix`** — the `let` block:
   ```nix
   username = "yourusername";    # output of `whoami`
   hostname = "your-mac-name";   # what you want the machine called
   system = "aarch64-darwin";    # or "x86_64-darwin" for Intel
   ```
2. **`home.nix`** — `programs.git.settings.user.name` and `.user.email`
3. **`darwin.nix`** — the `homebrew.casks` list (your GUI apps), `homebrew.masApps` (your App Store apps), and `system.defaults` (your preferences)
4. **First-run command** — pass your hostname explicitly: `sudo nix run nix-darwin -- switch --flake .#YOUR-HOSTNAME`

## How Claude Code is handled

Claude Code is unique in this config — it's the one tool not managed declaratively by Nix. Anthropic's native installer drops the binary at `~/.local/bin/claude` and the binary self-updates in the background, which is great for staying current but doesn't fit Nix's reproducibility model.

The compromise: a `system.activationScripts.postActivation` hook in `darwin.nix` runs Anthropic's native installer once if `~/.local/bin/claude` doesn't already exist. After that first install, Claude Code manages its own updates and the activation script becomes a no-op. `home.sessionPath` in `home.nix` ensures `~/.local/bin` is on PATH so the binary is found.

If full declarativeness matters more than continuous auto-updates, swap the activation script for one of:

- `homebrew.casks = [ "claude-code" ];` — updates whenever you `darwin-rebuild switch`, lags upstream by hours to days because of homebrew-cask review
- The [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix) overlay — `pkgs.claude-code` from a flake whose CI checks Anthropic releases hourly and bumps the package; updates pulled in via `nix flake update`

## Gotchas (the accumulated lessons)

**Untracked files are invisible to flakes.** When a flake lives in a git repo, Nix only sees files tracked by git. After adding any new file (e.g. splitting into modules), `git add` before rebuilding. Edits to already-tracked files work fine and produce a benign "Git tree is dirty" warning.

**`darwin-rebuild switch` requires `sudo`** as of mid-2025. The activation is now root-only. Touch ID for sudo (`security.pam.services.sudo_local.touchIdAuth = true;`) works after the first successful switch installs the PAM config — initial run still wants a password.

**`system.primaryUser` is required** if you set `homebrew.*` or any `system.defaults.*` option. It tells the (root-run) activation which user's preferences to apply. Set it to the username you log in with.

**Hostname auto-detection** uses the Mac's current `HostName`. On a fresh Mac that's still `Computers-Name`, not what's in your flake. First rebuild needs explicit `#hostname`; subsequent rebuilds can use a bare `--flake .` because `networking.hostName` is set during that first rebuild.

**Don't `nix profile install`.** Use the flake for permanent installs and `nix shell nixpkgs#thing` for one-offs. `nix profile` creates state outside your flake that won't be reproducible.

**Casks vs. nixpkgs.** When a tool exists in both, prefer nixpkgs. When it's a Mac GUI app (`.app` bundle), use a cask. When in doubt, search both: `nix search nixpkgs <name>` and `brew search <name>`.

**Mac App Store apps need a one-time GUI sign-in.** Open the App Store app and sign in once before relying on `homebrew.masApps`. After that, `mas search "App Name"` gives you the App ID to put in your config.

**Activation scripts use specific hook names.** Only `preActivation`, `postActivation`, `extraActivation`, etc. are actually invoked. Custom-named entries like `system.activationScripts.myThing` are silently ignored. Use `postActivation` (which is a `types.lines`, so multiple contributions merge safely).

**`sudo -u` doesn't reset `$HOME`** by default on macOS. If your activation script needs to run as a user (e.g. to install something into their home), use `sudo -H -u ${username}` — without `-H`, `$HOME` stays as `/var/root`.

**macOS major updates** (e.g. 15 → 16) can break nix-darwin for a few days until the maintainer ships a fix. If risk-averse, wait a week or two after a major release.

**The `or` warnings from Lix** when evaluating older nixpkgs lib code are benign. They'll clear up as upstream nixpkgs gets cleaned up. Suppress with `--extra-deprecated-features or-as-identifier` if they bother you.

**First build is slow, subsequent builds are fast.** Nix aggressively caches; most rebuilds after the first are seconds to a minute.

## References and inspiration

- [nix-darwin/nix-darwin](https://github.com/nix-darwin/nix-darwin) — the project itself
- [nix-community/home-manager](https://github.com/nix-community/home-manager)
- [zhaofengli/nix-homebrew](https://github.com/zhaofengli/nix-homebrew) — declarative Homebrew under nix-darwin
- [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config) — well-documented starter template
- [mitchellh/nixos-config](https://github.com/mitchellh/nixos-config) — reference config from a senior engineer
- [Mathias's `.macos`](https://github.com/mathiasbynens/dotfiles/blob/main/.macos) — canonical source for `defaults write` incantations, ported to nix-darwin's `system.defaults.*`
