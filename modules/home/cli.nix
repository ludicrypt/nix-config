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

    # media
    yt-dlp
    # plain ffmpeg (cached binary); ffmpeg-full builds from source on
    # aarch64-darwin and its codec deps' test suites get SIGKILLed in the sandbox.
    ffmpeg
  ];
}
