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
      # home-manager activation scripts run with a restricted PATH that excludes
      # /usr/bin. The outer /usr/bin/curl uses an absolute path so it always
      # works, but install.sh's internal `command -v curl` check runs in the
      # piped bash subshell and inherits our PATH — without /usr/bin it fails
      # with "Either curl or wget is required but neither is installed".
      export PATH="/usr/bin:/bin:$PATH"
      /usr/bin/curl -fsSL https://claude.ai/install.sh | bash || \
        echo "Claude Code install failed; run 'curl -fsSL https://claude.ai/install.sh | bash' manually." >&2
    fi
  '';

  home.activation.installOpenCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
      echo "Installing OpenCode..." >&2
      # Same restricted-PATH gotcha as installClaudeCode above; the opencode
      # installer additionally needs `unzip`, also at /usr/bin/unzip.
      export PATH="/usr/bin:/bin:$PATH"
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
