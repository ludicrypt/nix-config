{ ... }: {

  home.stateVersion = "25.11";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      extended = true;     # writes start time + duration; `fc -li` shows timestamps
    };

    shellAliases = {
      l = "eza -la --git";
      ll = "eza -la --git";
      ls = "eza";
      cat = "bat --paging=never";
      grep = "rg";
    };

    initContent = ''
      # --resolve-engines=false: don't let a project's package.json "engines"
      # field trigger fnm to install/switch Node over the nix-managed one.
      eval "$(fnm env --use-on-cd --resolve-engines=false --shell zsh)"
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
