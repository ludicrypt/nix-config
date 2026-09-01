{ pkgs, ... }: {

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  programs.uv.enable = true;
  programs.bun.enable = true;

  home.packages = with pkgs; [
    # python
    pixi
    # typescript / node
    nodejs   # baseline runtime for global tools (e.g. Codex CLI); fnm overrides per-project
    fnm
    # local LLM inference proxy (see ~/Development/agents/PLAN2.md)
    litellm  # LiteLLM proxy front door; the flake.lock pin must stay >=1.83.10 to clear
             # the security floor. nixpkgs, not brew (no brew formula); the default build
             # bundles the proxy server (fastapi/uvicorn/gunicorn). For S3/bedrock/MCP
             # proxy extras, use litellm.optional-dependencies.proxy instead.
  ];
}
