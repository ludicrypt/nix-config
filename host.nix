# host.nix — single source of truth for host-specific values.
# This is the only file you need to edit when forking this config for a new machine.
{
  username = "ludicrypt";
  hostname = "thegibson04";
  system   = "aarch64-darwin";   # or "x86_64-darwin" on Intel

  git = {
    name  = "ludicrypt";
    email = "68418401+ludicrypt@users.noreply.github.com";
  };

  repo = {
    url    = "https://github.com/ludicrypt/nix-config";
    sshUrl = "git@github.com:ludicrypt/nix-config.git";
  };
}
