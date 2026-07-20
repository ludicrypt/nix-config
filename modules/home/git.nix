{ pkgs, host, lib, ... }: {

  # Generate an SSH key on first activation and (re-)build allowed_signers from it
  # each rebuild so SSH-based git commit signing keeps working when the key rotates.
  #
  # WARNING: On a fresh-machine restore this generates a NEW key — it does not
  # recover the GitHub-registered key from the previous machine. If you want to
  # keep using the same key (and avoid having to add a new public key to GitHub),
  # restore ~/.ssh/id_ed25519 and id_ed25519.pub from backup BEFORE the first
  # `darwin-rebuild switch`. The `[ ! -f ... ]` guard below then skips the
  # ssh-keygen call.
  home.activation.generateSshKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "${host.username}@${host.hostname}" \
        -f "$HOME/.ssh/id_ed25519" -N ""
    fi
    mkdir -p "$HOME/.ssh"
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
      echo "${host.git.email} $(cat $HOME/.ssh/id_ed25519.pub)" \
        > "$HOME/.ssh/allowed_signers"
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        Hostname = "ssh.github.com";
        Port = 443;
        User = "git";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        # lazygit 0.61 replaced the single `git.paging` object with a `pagers`
        # array (cycle with the CyclePagers keybinding). It can't auto-migrate
        # here — the config file is a read-only nix store symlink.
        pagers = [
          {
            colorArg = "always";
            pager = "delta --side-by-side --paging=never";
          }
        ];
      };
    };
  };

  # Global gitignore — applied on top of each repo's own .gitignore, no opt-in
  # needed. For "noise everywhere": OS turds, editor swap files, dev caches.
  programs.git.ignores = [
    ".DS_Store"
    "*.swp"
    ".idea/"
    ".vscode/"
    ".direnv/"
    ".envrc.local"
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = host.git.name;
      user.email = host.git.email;
      init.defaultBranch = "main";
      pull.rebase = false;
      pull.ff = "only";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgSign = true;
      user.signingKey = "~/.ssh/id_ed25519.pub";
      "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };
}
