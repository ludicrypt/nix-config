{ pkgs, username, lib, ... }: {

  home.stateVersion = "25.11";

  # User-level CLI packages (most of your stuff goes here)
  home.packages = with pkgs; [
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
  ];

  # Make sure ~/.local/bin is on PATH so the Claude Code native binary
  # (installed via system.activationScripts in darwin.nix) is found
  home.sessionPath = [
    "$HOME/.local/bin"
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
      # any additional zsh config goes here
    '';
  };

  programs.starship.enable = true;  # nice prompt
  programs.fzf.enable = true;
  programs.zoxide.enable = true;    # smarter `cd`
}
