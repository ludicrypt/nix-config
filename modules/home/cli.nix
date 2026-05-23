{ pkgs, ... }: {

  programs.bat.enable = true;
  programs.htop.enable = true;

  home.packages = with pkgs; [
    # shell / file utilities
    ripgrep
    fd
    eza
    jq
    yq
    tree
    wget
    httpie

    # system monitoring
    btop
    lazydocker
  ];
}
