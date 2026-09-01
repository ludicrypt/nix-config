{ pkgs, ... }: {

  programs.bat.enable = true;
  programs.htop.enable = true;
  programs.btop.enable = true;
  programs.ripgrep.enable = true;
  programs.fd.enable = true;
  programs.jq.enable = true;
  programs.yt-dlp.enable = true;
  programs.lazydocker.enable = true;

  # git = true puts --git on the module's own `eza` alias, so every eza alias
  # (including the ll/l overrides in shell.nix) inherits it without repeating the flag.
  programs.eza = {
    enable = true;
    git = true;
  };

  home.packages = with pkgs; [
    # shell / file utilities
    yq
    tree
    wget
    httpie

    # security
    age

    # media
    # plain ffmpeg (cached binary); ffmpeg-full builds from source on
    # aarch64-darwin and its codec deps' test suites get SIGKILLed in the sandbox.
    ffmpeg
  ];
}
