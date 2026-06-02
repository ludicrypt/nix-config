{ pkgs, host, ... }: {

  # Tell nix-darwin to keep using Lix as the Nix implementation
  nix.package = pkgs.lix;

  # System-level activation tasks. User-level installs (Claude Code, OpenCode,
  # Codex) now live in modules/home/bootstrap.nix as home.activation entries.
  system.activationScripts.postActivation.text = ''
    # "Look up & data detectors" has no nix-darwin option; write it directly.
    sudo -H -u ${host.username} defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0

    # Install Rosetta 2 if not already present (needed by Docker Desktop on Apple Silicon).
    # oahd is the Rosetta runtime daemon; its absence means Rosetta isn't installed.
    if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
      softwareupdate --install-rosetta --agree-to-license || true
    fi

    # Enable remote access from another Mac (SSH + Screen Sharing).
    # No nix-darwin options exist for these; commands are idempotent so re-running on
    # every rebuild is fine. Authenticate from the client with this user's macOS password.
    #
    # Note: `systemsetup -setremotelogin on` silently fails on modern macOS without
    # Full Disk Access for the calling binary — so we drive launchd directly via
    # `enable` + `bootstrap` (the legacy `launchctl load -w` also silently no-ops on
    # Sonoma+). launchd socket-activates sshd, so port 22 starts listening immediately.
    #
    # Screen Sharing also has a TCC/privacy "permitted" flag that can ONLY be granted
    # by toggling Screen Sharing (or Remote Management) ON in System Settings →
    # General → Sharing, or via an MDM profile. Apple's own ARDAgent `kickstart` tool
    # confirms this. So on a fresh Mac, do that toggle once after the first rebuild —
    # the daemon persistence below keeps it working afterward.
    launchctl enable system/com.openssh.sshd 2>/dev/null || true
    launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    launchctl enable system/com.apple.screensharing 2>/dev/null || true
    launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

    # Stay reachable when asleep. `womp` = wake on magic packet (Ethernet);
    # `tcpkeepalive` keeps connections alive during sleep so wake-on-demand works.
    # Note: laptops with the lid closed still sleep — use a dummy HDMI dongle, or add
    # `pmset -a disablesleep 1` to disable sleep entirely (heavy hammer).
    pmset -a womp 1
    pmset -a tcpkeepalive 1
    # Display sleep timeout, split by power source (no nix-darwin option for the
    # battery/adapter split — power.sleep.display only sets one value for all sources).
    pmset -b displaysleep 5   # on battery: 5 min
    pmset -c displaysleep 10  # on power adapter: 10 min
    # "Prevent automatic sleeping on power adapter" (Battery > Options): disable full
    # system sleep on AC. No nix-darwin option splits sleep by source (power.sleep.computer
    # sets one value for all sources), so set it via pmset. Display still sleeps per the
    # displaysleep above; only system sleep is disabled while on the adapter.
    pmset -c sleep 0
    # Energy Mode on power adapter (no nix-darwin option). powermode: 0 = automatic, 1 = low, 2 = high.
    # Battery left at the macOS default (Automatic) — not set explicitly.
    pmset -c powermode 2      # on power adapter: High Power
    # Desktop-only (e.g. Mac Studio): never sleep so remote access always works.
    # pmset -a sleep 0

    # Restart the Dock after Homebrew casks have been installed so that
    # persistent-apps entries resolve on the first switch rather than needing a second pass.
    killall Dock 2>/dev/null || true
    # Restart Control Center so menu-bar toggles (Sound/Bluetooth/battery %) apply without a logout.
    killall ControlCenter 2>/dev/null || true
  '';

  # System-wide packages (rare — prefer home.packages for most things)
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
  ];

  # The user account this config is for
  users.users.${host.username} = {
    name = host.username;
    home = "/Users/${host.username}";
  };

  # Required by recent nix-darwin: tells the (root-run) activation which
  # user's preferences to apply for homebrew, system.defaults, etc.
  system.primaryUser = host.username;

  # Set the machine's hostname declaratively so darwin-rebuild can auto-match
  # against `darwinConfigurations.${hostname}` without needing `#name` on every command.
  # Three names because macOS tracks them separately:
  #   hostName     — Unix hostname (what `hostname` returns)
  #   localHostName — Bonjour name (e.g. thegibson04.local on the network)
  #   computerName  — friendly name shown in System Settings, AirDrop, etc.
  networking.hostName = host.hostname;
  networking.localHostName = host.hostname;
  networking.computerName = host.hostname;

  # macOS system defaults — declarative replacement for `defaults write`.
  # Dock lives in modules/darwin/homebrew.nix because dock.persistent-apps
  # references cask install paths.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;  # enable key repeat
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
      AppleShowAllExtensions = true;
      AppleKeyboardUIMode = 3;
      "com.apple.keyboard.fnState" = true;  # F1/F2/etc. act as standard function keys
      "com.apple.trackpad.scaling" = 1.5;
      AppleICUForce24HourTime = true;  # system-wide 24h time; the menu-bar clock follows this, not menuExtraClock.Show24Hour

      # Text-input substitutions. Quotes/dashes off so they don't mangle code;
      # period/capitalization/spelling left on for prose.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";  # search current folder by default
      FXPreferredViewStyle = "Nlsv";  # list view
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerVertSwipeGesture = 2;
    };

    # Menu-bar icons (Control Center submodule; true = show in menu bar).
    controlcenter = {
      Sound = true;
      Bluetooth = true;
      BatteryShowPercentage = false;
    };

    # Menu-bar clock format.
    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;          # 0 = when space allows, 1 = always, 2 = never
      ShowDayOfWeek = false;
      ShowSeconds = false;
    };

    WindowManager = {
      GloballyEnabled = false;                  # keep Stage Manager off
      EnableStandardClickToShowDesktop = false; # don't hide all windows when clicking the wallpaper
      StandardHideWidgets = true;               # Desktop & Dock > Show Widgets > On Desktop: Off
    };

    # NOTE: Accessibility > Zoom > "Use scroll gesture with modifier keys to zoom"
    # (universalaccess.closeViewScrollWheelToggle) is intentionally NOT set here.
    # com.apple.universalaccess is a TCC-protected domain — `defaults write` to it
    # fails ("Could not write domain com.apple.universalaccess; exiting") and ABORTS
    # the whole switch unless the terminal running darwin-rebuild has Full Disk Access.
    # Set it by hand in System Settings, or grant the terminal FDA and re-add the option.

    # Settings without a dedicated nix-darwin option, written to their raw domains.
    CustomUserPreferences = {
      # Desktop & Dock > "Close windows when quitting an application": Off.
      # The toggle is inverted — Off means windows ARE kept/restored, so the key is true.
      NSGlobalDomain = {
        NSQuitAlwaysKeepsWindows = true;
        # Hidden feature: drag a window from anywhere in it by holding Ctrl+Cmd
        # and click-dragging (not just the title bar). No System Settings UI for this.
        NSWindowShouldDragOnGesture = true;
      };
    };

    loginwindow = {
      GuestEnabled = false;
    };

    # NOTE: the lock-screen grace period ("require password after display
    # sleeps") is NOT settable here on macOS 26 — the OS ignores
    # com.apple.screensaver askForPasswordDelay (verified: sysadminctl reports
    # its own 300s delay regardless of this key). The real control is
    #   sysadminctl -screenLock immediate -password -
    # which prompts for the password and can't be expressed declaratively. Run
    # it once by hand; there's no nix-darwin option for it.

    # NOTE: the Spotlight menu-bar icon can't be controlled here on macOS 26.
    # Its visibility key (com.apple.Spotlight "NSStatusItem VisibleCC Item-0")
    # is owned by the Spotlight agent, which rewrites it back to 1 on every
    # launch — verified that a `defaults write … 0` reverts on login/agent
    # restart. The legacy `com.apple.systemuiserver menuExtras` / Menu Extras
    # bundle trick is also dead (no Spotlight.menu exists). Only fix is the
    # System Settings > Menu Bar toggle for Spotlight, which signals the agent
    # to change its own state and persists.
  };

  # Auto-recover from kernel panics so the machine comes back online without
  # physical intervention — important when relying on remote access.
  power.restartAfterFreeze = true;
  # Desktop-only (Mac mini/Studio/Pro). Laptops reject this with
  # "restarting after power failure is not supported on your machine".
  # power.restartAfterPowerFailure = true;

  # Required boilerplate
  system.stateVersion = 6;
  nixpkgs.hostPlatform = host.system;

  # litellm (modules/home/dev.nix) pulls in python a2a-sdk, whose test suite errors
  # against this pin's FastAPI version (pickling of FastAPI.setup.<locals>.openapi —
  # the package itself is fine). There's no aarch64-darwin cache bottle, so it builds
  # from source and the failing tests abort the build. Skip its checks so litellm can
  # build; remove once nixpkgs fixes the a2a-sdk test. Reaches home-manager pkgs too
  # via home-manager.useGlobalPkgs = true in flake.nix.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          a2a-sdk = pyprev.a2a-sdk.overridePythonAttrs (_: { doCheck = false; });
        })
      ];
    })
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # @admin + the configured user can talk to nix-daemon, use binary caches,
    # and substitute paths without sudo prompts.
    trusted-users = [ "@admin" host.username ];
    max-jobs = "auto";
    builders-use-substitutes = true;
    # Hardlink identical files in the store as they're added (continuous dedup);
    # complements the periodic nix.optimise.automatic pass below.
    auto-optimise-store = true;
    # Silences the constant "Git tree is dirty" warning when editing the flake repo.
    warn-dirty = false;
  };

  # Weekly garbage collection — without this /nix/store grows unboundedly on a
  # daily-driver Mac with frequent rebuilds. Sundays at 03:00 keeps the last 30
  # days of generations around as a rollback safety net.
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  # Periodic store-wide optimisation in case auto-optimise-store missed any
  # duplicates. Cheap; just runs `nix-store --optimise` on a schedule.
  nix.optimise.automatic = true;

  # Use Touch ID and Apple Watch for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.watchIdAuth = true;
}
