{ pkgs, ... }: {

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

  programs.git = {
    enable = true;
    settings = {
      user.name = "ludicrypt";
      user.email = "68418401+ludicrypt@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
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
