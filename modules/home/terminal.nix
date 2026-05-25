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
    # Disabled — any custom shader forces a continuous GPU redraw loop while focused
    # (~30% GPU here); custom-shader-animation = false does not gate it. Known Ghostty
    # limitation (ghostty-org/ghostty#11928, discussions #8818/#10678).
    # custom-shader = shaders/cursor_warp.glsl
  '';
}
