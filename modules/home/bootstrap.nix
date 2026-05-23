{ pkgs, lib, ... }: {

  # PATH additions for the three self-updating CLIs installed below.
  # Claude Code lives at ~/.local/bin; OpenCode at ~/.opencode/bin; Codex (installed
  # via bun) at ~/.bun/bin.
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
    "$HOME/.bun/bin"
  ];

  # These three CLIs self-update from their own installers, so Nix can't sanely
  # manage their versions. Trigger the install once if absent, then they
  # auto-update in the background.
  #
  # Previously these lived in darwin.nix's system.activationScripts.postActivation
  # wrapped in `sudo -H -u $username` because that block runs as root. As
  # home.activation entries they already run as the user, so the sudo gymnastics
  # are gone.

  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.local/bin/claude" ] && [ ! -f "$HOME/.claude/bin/claude" ]; then
      echo "Installing Claude Code native binary..." >&2
      /usr/bin/curl -fsSL https://claude.ai/install.sh | bash || \
        echo "Claude Code install failed; run 'curl -fsSL https://claude.ai/install.sh | bash' manually." >&2
    fi
  '';

  home.activation.installOpenCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
      echo "Installing OpenCode..." >&2
      /usr/bin/curl -fsSL https://opencode.ai/install | bash || \
        echo "OpenCode install failed; run 'curl -fsSL https://opencode.ai/install | bash' manually." >&2
    fi
  '';

  home.activation.installCodexCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.bun/bin/codex" ]; then
      echo "Installing Codex CLI..." >&2
      ${pkgs.bun}/bin/bun add --global @openai/codex || \
        echo "Codex CLI install failed; run 'bun add --global @openai/codex' manually." >&2
    fi
  '';
}
