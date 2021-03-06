{ config, pkgs, ... }:
{
  programs = {
    bash = {
      enable = true;
      historyFileSize = -1;
      historySize = -1;
      bashrcExtra = ''
        # Set ulimit soft and hard limits to match launchctl's limits.
        set_ulimit() {
            local soft=$1
            local hard=$2
            ulimit -H -n "$hard"
            ulimit -S -n "$soft"
        }
        set_ulimit $(launchctl limit maxfiles | awk '{ print $2,$3 }')
        unset set_ulimit

        # Enable per-session history.
        SHELL_SESSION_HISTORY=1

        # TODO: avoid depending on Apple's script and just implement it here.
        if [ -e /etc/bashrc_Apple_Terminal ]; then
            source /etc/bashrc_Apple_Terminal
            # Prevent shell session logs from being deleted.
            shell_session_delete_expired() {
                (umask 077; touch "$SHELL_SESSION_TIMESTAMP_FILE")
            }
        fi
      '';
      initExtra = ''
        PS1="\u@\h:\W \$ "
      '';
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      stdlib = ''
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
            echo "''${direnv_layout_dirs[$PWD]:=$(
                echo -n "$XDG_CACHE_HOME"/direnv/layouts/
                echo -n "$PWD" | shasum | cut -d ' ' -f 1
            )}"
        }
      '';
      enableBashIntegration = true;
    };

    git = {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
      };
      userName = "Luke Rewega";
      userEmail = "lrewega@buf.build";
    };

    htop.enable = true;

    ssh = {
      enable = true;
      extraConfig = ''
        IdentityFile ~/.ssh/id_ed25519
        AddKeysToAgent yes
        IgnoreUnknown UseKeychain
            UseKeychain yes
      '';
    };

    vim = {
      enable = true;

      plugins = with pkgs.vimPlugins; [
        vim-commentary
        vim-fugitive
        vim-gitgutter
        vim-go
        vim-sensible
        vim-sleuth
        mkdx
      ];

      settings = {
        relativenumber = true;
      };

      extraConfig = ''
        set hlsearch

        let g:mkdx#settings = {
        \ 'map': { 'prefix': '<Space>' }
        \ }
      '';

    };
  };

  home.sessionVariables.EDITOR = "vim";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";
}
