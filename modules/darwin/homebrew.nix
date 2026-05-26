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
      # ThermalForge — open-source fan control for Apple Silicon (replaces TG Pro).
      # DISABLED 2026-05-26: the formula is broken upstream. It builds git tag
      # v0.1.0, which predates ThermalForge.icns + Scripts/generate-icon.swift, so
      # the icon-generation step fails ("error opening input file
      # 'Scripts/generate-icon.swift'"). The fix exists only on the unreleased main
      # branch — see https://github.com/ProducerGuy/homebrew-tap/issues/1.
      #
      # Installed manually from source instead (upstream's ./setup.sh, built from
      # main): CLI at /usr/local/bin/thermalforge, menu-bar app in /Applications,
      # daemon at /Library/LaunchDaemons/com.thermalforge.daemon.plist. Update it
      # with `git pull && ./setup.sh` in the checkout (~/Developer/ThermalForge).
      #
      # BEFORE re-enabling this brew (once a fixed release is tagged): first run
      # `sudo /usr/local/bin/thermalforge uninstall` to remove the source install,
      # otherwise the brew copy (/opt/homebrew/bin) and the source copy fight over
      # the same daemon plist. The dormant setup step in system.nix (postActivation)
      # then takes over the one-time `thermalforge install`.
      # "ProducerGuy/tap/thermalforge"
      # MTPLX — native MTP speculative-decoding runtime for MLX on Apple Silicon.
      # CLI only; first run `mtplx start` launches an interactive setup wizard.
      "youssofal/mtplx/mtplx"
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
      "orbstack"
      # "tg-pro"  # uninstalled 2026-05-26 to trial ThermalForge (see brews); kept commented in case we switch back
      "visual-studio-code@insiders"
      "zen"
    ];

    masApps = {
      # Format: "App Name" = appStoreID;
      # Find IDs with: mas search "app name"
      #
      # Family Sharing caveat: `mas install` uses a StoreKit endpoint that
      # can only initiate downloads for apps the current Apple ID directly
      # purchased. Family-Sharing-shared apps fail on first bootstrap with
      # "No downloads initiated for ADAM ID …" — install those manually via
      # the App Store GUI once, then subsequent rebuilds see them present
      # and no-op. See mas-cli/mas#164. The Pro Apps bundle below is the
      # affected group on this machine.
      "Blackmagic Disk Speed Test" = 425264550;
      "Cinebench" = 1438772273;
      # Apple Pro Apps — Family Sharing, install manually on first bootstrap
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
    wvous-bl-corner = 10;  # bottom-left hot corner: Put Display to Sleep
    # App Exposé via three-finger swipe down (pairs with the existing
    # trackpad.TrackpadThreeFingerVertSwipeGesture = 2 in system.nix).
    showAppExposeGestureEnabled = true;
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
