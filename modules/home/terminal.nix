{ pkgs, inputs, ... }: {

  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
  };

  # Ghostty shaders pulled in as a flake input so the cursor warp shader is reproducible.
  home.file.".config/ghostty/shaders".source = inputs.ghostty-shaders;

  home.file.".config/ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font Mono
    font-size = 13
    theme = Gruvbox Dark Hard
    background-opacity = 0.75
    background-blur-radius = 16
    custom-shader = shaders/cursor_warp.glsl
  '';
}
