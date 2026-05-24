{ pkgs, ... }: {

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  home.packages = with pkgs; [
    # python
    uv
    pixi
    # typescript / node
    nodejs   # baseline runtime for global tools (e.g. Codex CLI); fnm overrides per-project
    bun
    fnm
  ];
}
