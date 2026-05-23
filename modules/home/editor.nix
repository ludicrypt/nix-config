{ pkgs, lib, config, ... }: {

  home.packages = [ pkgs.neovim ];

  # Bootstrap the AstroNvim user template into ~/.config/nvim on first run.
  # Only `init.lua` (and other top-level files) come from the template; the entire
  # `lua/` tree is owned by this repo and symlinked in below, so the template's
  # `lua/` directory is removed each activation to keep the symlink target clear.
  # Runs *before* checkLinkTargets so home-manager's symlink doesn't see a conflict.
  home.activation.bootstrapAstroNvim = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
      echo "Bootstrapping AstroNvim template into ~/.config/nvim..." >&2
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/AstroNvim/template "$HOME/.config/nvim"
      rm -rf "$HOME/.config/nvim/.git"
    fi
    # Always clear the template's lua/ dir so home-manager can place its symlink there.
    if [ -d "$HOME/.config/nvim/lua" ] && [ ! -L "$HOME/.config/nvim/lua" ]; then
      rm -rf "$HOME/.config/nvim/lua"
    fi
  '';

  # Mutable symlink to the lua/ tree in this repo — edits are live, no rebuild needed.
  # Drop a new .lua file under nvim/lua/plugins/ in the repo and it appears in nvim automatically.
  xdg.configFile."nvim/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/nvim/lua";
}
