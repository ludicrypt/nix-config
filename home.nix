{ pkgs, username, lib, inputs, ... }: {

  home.stateVersion = "25.11";

  # User-level CLI packages (most of your stuff goes here)
  home.file.".config/ghostty/shaders".source = inputs.ghostty-shaders;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # shell utilities
    ripgrep
    fd
    bat
    eza
    jq
    yq
    fzf
    htop
    tree
    wget
    httpie

    # terminal / system monitoring
    tmux
    lazydocker
    btop

    # dev tools
    gh
    delta
    lazygit
    # python
    uv
    pixi
    # typescript / node
    nodejs  # baseline runtime for global tools (e.g. Codex CLI); fnm overrides per-project
    bun
    fnm
  ];

  # Make sure ~/.local/bin is on PATH so the Claude Code native binary
  # (installed via system.activationScripts in darwin.nix) is found
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"  # OpenCode native install
    "$HOME/.bun/bin"       # bun global installs (e.g. Codex CLI)
  ];

  home.activation.generateSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "${username}" \
        -f "$HOME/.ssh/id_ed25519" -N ""
    fi
    # Rebuild allowed_signers from the current public key each activation
    mkdir -p "$HOME/.ssh"
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
      echo "68418401+ludicrypt@users.noreply.github.com $(cat $HOME/.ssh/id_ed25519.pub)" \
        > "$HOME/.ssh/allowed_signers"
    fi
  '';

  home.file.".config/ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font Mono
    font-size = 13
    theme = Gruvbox Dark Hard
    background-opacity = 0.75
    background-blur-radius = 16
    custom-shader = shaders/cursor_warp.glsl
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        Hostname = "ssh.github.com";
        Port = 443;
        User = "git";
      };
    };
  };

  home.activation.lazygitConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/Library/Application Support/lazygit"
    cat > "$HOME/Library/Application Support/lazygit/config.yml" << 'LAZYGIT_EOF'
git:
  paging:
    colorArg: always
    pager: delta --side-by-side --paging=never
LAZYGIT_EOF
  '';

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "ludicrypt";
      user.email = "68418401+ludicrypt@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      pull.ff = "only";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgSign = true;
      user.signingKey = "~/.ssh/id_ed25519.pub";
      "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      l = "eza -la --git";
      ll = "eza -la --git";
      ls = "eza";
      cat = "bat --paging=never";
      grep = "rg";
    };

    initContent = ''
      eval "$(fnm env --use-on-cd --shell zsh)"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
}
