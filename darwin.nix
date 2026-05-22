{ pkgs, username, hostname, ... }: {

  # Tell nix-darwin to keep using Lix as the Nix implementation
  nix.package = pkgs.lix;

  # Bootstrap Claude Code via Anthropic's native installer if not already present.
  # After this first install, Claude Code auto-updates itself in the background,
  # so Nix triggers the install but doesn't manage the version.
  # Must use `postActivation` (a hook nix-darwin actually invokes) rather than a
  # custom-named activation script, which gets silently ignored.
  system.activationScripts.postActivation.text = ''
    if [ ! -f "/Users/${username}/.local/bin/claude" ] && \
       [ ! -f "/Users/${username}/.claude/bin/claude" ]; then
      echo "Installing Claude Code native binary for ${username}..." >&2
      sudo -H -u ${username} bash -c 'curl -fsSL https://claude.ai/install.sh | bash' || \
        echo "Claude Code install failed; run 'curl -fsSL https://claude.ai/install.sh | bash' manually." >&2
    fi

    # "Look up & data detectors" has no nix-darwin option; write it directly.
    sudo -H -u ${username} defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0

    # Install Rosetta 2 if not already present (needed by Docker Desktop on Apple Silicon).
    # oahd is the Rosetta runtime daemon; its absence means Rosetta isn't installed.
    if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
      softwareupdate --install-rosetta --agree-to-license || true
    fi

    # OpenCode — native curl installer, self-updates at startup via `opencode upgrade`.
    # Installs to ~/.opencode/bin (added to sessionPath in home.nix).
    if [ ! -f "/Users/${username}/.opencode/bin/opencode" ]; then
      echo "Installing OpenCode for ${username}..." >&2
      sudo -H -u ${username} bash -c 'curl -fsSL https://opencode.ai/install | bash' || \
        echo "OpenCode install failed; run 'curl -fsSL https://opencode.ai/install | bash' manually." >&2
    fi

    # Codex CLI — installed via bun (already Nix-managed), self-updates via `codex update`.
    # Uses bash -lc so the user's Nix profile is sourced and bun is on PATH.
    if [ ! -f "/Users/${username}/.bun/bin/codex" ]; then
      echo "Installing Codex CLI for ${username}..." >&2
      sudo -H -u ${username} bash -lc 'bun add --global @openai/codex' || \
        echo "Codex CLI install failed; run 'bun add --global @openai/codex' manually." >&2
    fi
  '';

  # System-wide packages (rare — prefer home.packages for most things)
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
  ];

  # The user account this config is for
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Required by recent nix-darwin: tells the (root-run) activation which
  # user's preferences to apply for homebrew, system.defaults, etc.
  system.primaryUser = username;

  # Set the machine's hostname declaratively so darwin-rebuild can auto-match
  # against `darwinConfigurations.${hostname}` without needing `#name` on every command.
  # Three names because macOS tracks them separately:
  #   hostName     — Unix hostname (what `hostname` returns)
  #   localHostName — Bonjour name (e.g. thegibson04.local on the network)
  #   computerName  — friendly name shown in System Settings, AirDrop, etc.
  networking.hostName = hostname;
  networking.localHostName = hostname;
  networking.computerName = hostname;

  # Homebrew — managed declaratively by nix-darwin
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";  # Set to "uninstall" if you want a strict declarative regime
    };

    brews = [
      # CLI tools that aren't in nixpkgs or are better as casks
    ];

    casks = [
      "chatgpt"
      "claude"
      "codex-app"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "lm-studio"
      "obsidian"
      "ollama-app"
      "tg-pro"
      "visual-studio-code@insiders"
    ];

    masApps = {
      # Format: "App Name" = appStoreID;
      # Find IDs with: mas search "app name"
      # "Xcode" = 497799835;  # install manually from the App Store — mas fails as root
    };
  };

  # nix-homebrew manages the Homebrew installation itself
  nix-homebrew = {
    enable = true;
    enableRosetta = false;  # set true if you want Rosetta brew on Apple Silicon
    user = username;
    autoMigrate = true;
  };

  # macOS system defaults — declarative replacement for `defaults write`
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;  # enable key repeat
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
      AppleShowAllExtensions = true;
      AppleKeyboardUIMode = 3;
      "com.apple.trackpad.scaling" = 1.5;
    };

    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
      mru-spaces = false;
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/Applications/Google Chrome.app"
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
  };

  # Required boilerplate
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";  # change if Intel
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
