{ pkgs, host, ... }: {

  # Homebrew — managed declaratively by nix-darwin
  homebrew = {
    enable = true;
    onActivation = {
      # Must be false when using nix-homebrew: brew tries to auto-update its taps,
      # but nix-homebrew makes them read-only, which aborts `brew bundle` before
      # masApps can install. See nix-darwin#1722, nix-homebrew#131.
      autoUpdate = false;
      upgrade = true;
      cleanup = "none";  # Set to "uninstall" if you want a strict declarative regime
    };

    brews = [
      "mactop"  # nixpkgs build fails in sandbox; Homebrew formula works fine
    ];

    casks = [
      "brave-browser"
      "chatgpt"
      "claude"
      "codex-app"
      "docker-desktop"
      "duckduckgo"
      "geekbench"
      "ghostty"
      "google-chrome"
      "lm-studio"
      "mx-power-gadget"
      "obsidian"
      "ollama-app"
      "tg-pro"
      "visual-studio-code@insiders"
      "zen"
    ];

    masApps = {
      # Format: "App Name" = appStoreID;
      # Find IDs with: mas search "app name"
      "Blackmagic Disk Speed Test" = 425264550;
      "Cinebench" = 1438772273;
      "Compressor" = 424390742;
      "Final Cut Pro" = 424389933;
      "Logic Pro" = 634148309;
      "MainStage" = 634159523;
      "Motion" = 434290957;
      "NordVPN" = 905953485;
      "Windows App" = 1295203466;
      "WireGuard" = 1451685025;
      # After install, run: sudo xcodebuild -license accept && xcode-select --install
      "Xcode" = 497799835;
    };
  };

  # nix-homebrew manages the Homebrew installation itself
  nix-homebrew = {
    enable = true;
    enableRosetta = false;  # set true if you want Rosetta brew on Apple Silicon
    user = host.username;
    autoMigrate = true;
  };

  # Dock — co-located with Homebrew because persistent-apps references cask
  # install paths. Adding a new GUI app is a one-file edit: cask + dock entry.
  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    tilesize = 48;
    mru-spaces = false;
    persistent-apps = [
      "/System/Applications/Apps.app"
      "/Applications/Google Chrome.app"
      "/Applications/Brave Browser.app"
      "/Applications/Zen.app"
      "/Applications/DuckDuckGo.app"
      "/Applications/Xcode.app"
      "/Applications/Visual Studio Code - Insiders.app"
      "/Applications/Ghostty.app"
      "/Applications/LM Studio.app"
      "/Applications/Obsidian.app"
      "/Applications/Claude.app"
      "/Applications/ChatGPT.app"
      "/Applications/Codex.app"
    ];
  };
}
