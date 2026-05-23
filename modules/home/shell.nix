{ ... }: {

  home.stateVersion = "25.11";

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
