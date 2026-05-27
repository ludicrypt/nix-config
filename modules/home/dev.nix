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
    # local LLM inference proxy (see ~/Development/agents/PLAN2.md)
    litellm  # LiteLLM proxy front door, pinned 1.83.14 (clears the >=1.83.10 security
             # floor). nixpkgs, not brew (no brew formula); the default build bundles the
             # proxy server (fastapi/uvicorn/gunicorn). For S3/bedrock/MCP proxy extras,
             # use litellm.optional-dependencies.proxy instead.
  ];
}
