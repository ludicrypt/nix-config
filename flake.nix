{
  description = "Personal macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    ghostty-shaders = {
      url = "github:sahaj-b/ghostty-cursor-shaders";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
  let
    # All host-specific values (username, hostname, system, git, repo) live in
    # ./host.nix — the only file you edit when forking this config.
    host = import ./host.nix;
  in {
    # Exposed so tooling (bootstrap.sh) can read values via `nix eval --raw .#host.hostname`
    inherit host;

    darwinConfigurations.${host.hostname} = nix-darwin.lib.darwinSystem {
      inherit (host) system;
      specialArgs = { inherit inputs host; };
      modules = [
        ./modules/darwin/system.nix
        ./modules/darwin/homebrew.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Back up pre-existing files instead of halting activation when something
          # outside home-manager's control (e.g. a `gh auth login` writing config.yml)
          # is in the way. Backups land as foo.hm-backup next to the original.
          home-manager.backupFileExtension = "hm-backup";
          home-manager.users.${host.username} = {
            imports = [
              ./modules/home/shell.nix
              ./modules/home/git.nix
              ./modules/home/editor.nix
              ./modules/home/terminal.nix
              ./modules/home/dev.nix
              ./modules/home/cli.nix
              ./modules/home/bootstrap.nix
            ];
          };
          home-manager.extraSpecialArgs = { inherit inputs host; };
        }
      ];
    };
  };
}
