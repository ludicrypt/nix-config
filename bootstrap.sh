#!/usr/bin/env bash
# bootstrap.sh — Fresh-machine setup for ludicrypt/nix-config
#
# Fetch and run anonymously (repo is public):
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/ludicrypt/nix-config/main/bootstrap.sh)
#
# Forks override the cloned repo URL, target host, and expected user via env vars:
#
#   REPO_URL=https://github.com/you/nix-config \
#   FLAKE_HOSTNAME=mybox \
#   EXPECTED_USER=me \
#     bash <(curl -fsSL https://raw.githubusercontent.com/you/nix-config/main/bootstrap.sh)
#
# Idempotent: safe to re-run; each step skips if already done.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/ludicrypt/nix-config}"
REPO_DIR="$HOME/.config/nix-config"
FLAKE_HOSTNAME="${FLAKE_HOSTNAME:-thegibson04}"
EXPECTED_USER="${EXPECTED_USER:-ludicrypt}"
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
  warn "Before the build succeeds, update host.nix:"
  warn "  system = \"x86_64-darwin\""
fi

if [[ "$USER" != "$EXPECTED_USER" ]]; then
  warn "Current user is '$USER' but host.nix expects '$EXPECTED_USER'."
  warn "The build will fail unless you update username/hostname in flake.nix first."
  read -rp "  Continue anyway? [y/N] " _reply </dev/tty
  # Use a case glob rather than ${var,,} so we work with macOS's built-in
  # bash 3.2, which the script runs under before Nix is installed.
  case "$_reply" in
    [yY]) ;;
    *)    echo "Aborted."; exit 1 ;;
  esac
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
  info "Cloning $REPO_URL → $REPO_DIR…"
  git clone "$REPO_URL" "$REPO_DIR"
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
