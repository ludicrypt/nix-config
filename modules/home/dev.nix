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

  # Installs nodejs, the baseline runtime for global tools; fnm overrides it per-project.
  # The default global prefix is inside the read-only nodejs store path, so
  # `npm install -g` fails with EACCES without a writable one. Not ~/.npm (the module's
  # default), which is npm's cache dir.
  programs.npm = {
    enable = true;
    settings.prefix = "\${HOME}/.npm-global";
  };

  home.packages = with pkgs; [
    # python
    pixi
    # typescript / node
    fnm
    # local LLM inference proxy (see ~/Development/agents/PLAN2.md)
    litellm  # LiteLLM proxy front door; the flake.lock pin must stay >=1.83.10 to clear
             # the security floor. nixpkgs, not brew (no brew formula); the default build
             # bundles the proxy server (fastapi/uvicorn/gunicorn). For S3/bedrock/MCP
             # proxy extras, use litellm.optional-dependencies.proxy instead.
  ];
}
