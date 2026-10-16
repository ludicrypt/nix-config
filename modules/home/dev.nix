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
    # reverse engineering
    ghidra  # REA's native-analysis engine; REA 6.5.0 accepts the 12.1.x line
  ];

  # Stable paths for REA's GHIDRA_INSTALL_DIR and JAVA_HOME (set in the `rea` MCP
  # entry in ~/.claude.json): store paths change on every flake update. REA
  # launches support/analyzeHeadless directly, bypassing the wrapper that would
  # otherwise supply the JDK.
  home.file.".local/share/ghidra".source = "${pkgs.ghidra}/lib/ghidra";
  home.file.".local/share/jdk21".source = pkgs.jdk21.home;
}
