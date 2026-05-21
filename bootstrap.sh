#!/usr/bin/env bash
# bootstrap.sh — Fresh-machine setup for ludicrypt/nix-config
#
# This is a private repo. Fetch and run with a GitHub token:
#
#   TOKEN=ghp_xxx
#   bash <(curl -fsSL -H "Authorization: token $TOKEN" \
#     https://raw.githubusercontent.com/ludicrypt/nix-config/main/bootstrap.sh)
#
# Pass the same token so the script can clone the repo:
#
#   GITHUB_TOKEN=ghp_xxx TOKEN=ghp_xxx bash <(curl ...)
#
# Or set GITHUB_TOKEN separately — if unset, the clone step tries SSH instead.
# Idempotent: safe to re-run; each step skips if already done.
set -euo pipefail

REPO_URL="https://github.com/ludicrypt/nix-config"
REPO_DIR="$HOME/.config/nix-config"
FLAKE_HOSTNAME="thegibson04"
EXPECTED_USER="ludicrypt"
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"

# ── Colors ────────────────────────────────────────────────────────────────────
_bold=$(tput bold 2>/dev/null || true)
_blue=$(tput setaf 4 2>/dev/null || true)
_green=$(tput setaf 2 2>/dev/null || true)
_yellow=$(tput setaf 3 2>/dev/null || true)
_red=$(tput setaf 1 2>/dev/null || true)
_reset=$(tput sgr0 2>/dev/null || true)

info() { printf '%s==>%s %s\n'   "${_bold}${_blue}"   "${_reset}" "$*"; }
ok()   { printf '%s  ✓%s %s\n'   "${_bold}${_green}"  "${_reset}" "$*"; }
warn() { printf '%s  !%s %s\n'   "${_bold}${_yellow}" "${_reset}" "$*"; }
die()  { printf '%sERROR:%s %s\n' "${_bold}${_red}"   "${_reset}" "$*" >&2; exit 1; }

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ "$(uname -s)" == "Darwin" ]] || die "This script is macOS-only."
[[ "$EUID" -ne 0 ]] || die "Run as your regular user, not root."

if [[ "$(uname -m)" != "arm64" ]]; then
  warn "Intel Mac detected."
  warn "Before the build succeeds, update flake.nix and darwin.nix:"
  warn "  system = \"x86_64-darwin\"   (flake.nix)"
  warn "  nixpkgs.hostPlatform = \"x86_64-darwin\"   (darwin.nix)"
fi

if [[ "$USER" != "$EXPECTED_USER" ]]; then
  warn "Current user is '$USER' but flake.nix expects '$EXPECTED_USER'."
  warn "The build will fail unless you update username/hostname in flake.nix first."
  read -rp "  Continue anyway? [y/N] " _reply </dev/tty
  [[ "${_reply,,}" == "y" ]] || { echo "Aborted."; exit 1; }
fi

# ── Xcode Command Line Tools ──────────────────────────────────────────────────
if xcode-select -p &>/dev/null; then
  ok "Xcode Command Line Tools already installed"
else
  info "Triggering Xcode Command Line Tools install (click Install in the dialog)…"
  xcode-select --install 2>/dev/null || true
  info "Waiting for CLT installation to complete…"
  until xcode-select -p &>/dev/null; do sleep 10; done
  ok "Xcode Command Line Tools installed"
fi

# ── Lix ───────────────────────────────────────────────────────────────────────
if command -v nix &>/dev/null || [[ -x "$NIX_BIN" ]]; then
  ok "Nix/Lix already installed"
else
  info "Installing Lix (you'll be shown an install plan and asked to confirm)…"
  curl -sSf -L https://install.lix.systems/lix | sh -s -- install
  ok "Lix installed"
fi

# Source Nix profile into this shell session
for _sh in \
  "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" \
  "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" \
  "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
  # shellcheck source=/dev/null
  [[ -f "$_sh" ]] && { source "$_sh"; break; }
done

# Resolve the nix binary — prefer the full path so sudo finds it too
_nix="$NIX_BIN"
command -v nix &>/dev/null && _nix="$(command -v nix)"
[[ -x "$_nix" ]] || die "nix not found after install. Open a new terminal and re-run."

# ── Clone repo ────────────────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/.git" ]]; then
  info "Repo already present at $REPO_DIR — pulling latest…"
  git -C "$REPO_DIR" pull --ff-only
  ok "Repo up to date"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    info "Cloning via HTTPS with token → $REPO_DIR…"
    git clone "https://ludicrypt:${GITHUB_TOKEN}@github.com/ludicrypt/nix-config.git" "$REPO_DIR"
    # Remove the embedded token from the remote so it doesn't persist in .git/config
    git -C "$REPO_DIR" remote set-url origin "$REPO_URL"
  else
    info "GITHUB_TOKEN not set — cloning via SSH (requires key on GitHub)…"
    git clone "git@github.com:ludicrypt/nix-config.git" "$REPO_DIR"
  fi
  ok "Repo cloned"
fi

# Nix flakes only evaluate git-tracked files; stage everything.
git -C "$REPO_DIR" add -A

# ── Build & activate ──────────────────────────────────────────────────────────
cd "$REPO_DIR"

if command -v darwin-rebuild &>/dev/null; then
  info "darwin-rebuild found — switching (this is a subsequent run)…"
  sudo darwin-rebuild switch --flake "$REPO_DIR"
else
  info "Running first nix-darwin build — this downloads a lot, go grab a coffee…"
  sudo "$_nix" \
    --extra-experimental-features "nix-command flakes" \
    run nix-darwin -- switch --flake ".#${FLAKE_HOSTNAME}"
fi

echo ""
ok "Bootstrap complete!"
echo "  Open a new terminal (or run: exec zsh) to load your new shell environment."
