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

    # programs.eza supplies ls/ll/la/lt/lla at mkDefault priority, and folds --git
    # into the `eza` alias itself; these override the two whose flags differ.
    shellAliases = {
      l = "eza -la";
      ll = "eza -la";
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
