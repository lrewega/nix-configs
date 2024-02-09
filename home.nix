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

    git =
      let
        gitBufUserAndEmailConfig = pkgs.writeText "buf_user_and_email.inc" ''
          [user]
            name = Luke Rewega
            email = lrewega@buf.build
        '';
      in
      {
        enable = true;
        package = pkgs.gitAndTools.gitFull;
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
          url."ssh://git@github.com/".insteadOf = "https://github.com/";
        };
        userName = "Luke Rewega";
        userEmail = "lrewega@c32.ca";
        includes = [
          {
            condition = "gitdir:~/wrk/github.com/bufbuild/";
            path = "${gitBufUserAndEmailConfig}";
          }
          {
            condition = "gitdir:~/wrk/github.com/connectrpc/";
            path = "${gitBufUserAndEmailConfig}";
          }
        ];
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


    vim =
      let
        lsp = {
          yaml-language-server = "${pkgs.yaml-language-server}/bin/yaml-language-server";
          json-language-server = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          nix-language-server = "${pkgs.nil}/bin/nil";
        };
        nixpkgs-fmt = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        extraPlugins = {
          vim-synthwave84 = pkgs.vimUtils.buildVimPlugin {
            name = "vim-synthwave84";
            src = pkgs.fetchFromGitHub {
              owner = "artanikin";
              repo = "vim-synthwave84";
              rev = "a5caa80d9e1a7021f9ec6c06a96d09dfc2d99ed1";
              hash = "sha256-5+rOp2xDdtIMxMdvV0N18yTSQuSzYIfnFvwNeufaDgQ=";
            };
          };
          badwolf = pkgs.vimUtils.buildVimPlugin {
            name = "badwolf";
            src = pkgs.fetchFromGitHub {
              owner = "sjl";
              repo = "badwolf";
              rev = "3fae5a19ed14b37f025abc366f2e738046b7cb42";
              hash = "sha256-RWQfEXSrKRTMTPw17du0GfRDTafDBtuug4hwWUc6vcg=";
            };
          };
        };
      in
      {
        enable = true;
        # Full list of available plugins:
        # https://github.com/NixOS/nixpkgs/blob/nixpkgs-unstable/pkgs/applications/editors/vim/plugins/vim-plugin-names
        plugins =
          builtins.attrValues
            {
              inherit (pkgs.vimPlugins)
                # Languages
                mkdx
                vim-go
                vim-helm
                vim-lsp
                vim-nix
                # Themes
                gruvbox
                jellybeans-vim
                molokai
                onedark-vim
                papercolor-theme
                # Misc.
                nerdtree
                vim-commentary
                vim-fugitive
                vim-gitgutter
                vim-sensible
                vim-sleuth
                ;
            } ++ builtins.attrValues extraPlugins;

        extraConfig = ''
          set hlsearch
          set relativenumber
          set textwidth=100

          if has('termguicolors')
            set termguicolors
          endif
          set background=dark

          syntax enable " Just in case.

          augroup FixColorScheme
            autocmd colorscheme * call s:fixColorScheme()
          augroup END
          function s:fixColorScheme()
            " Some colorschemes muck up SignColumn, transparent seems to work reliably.
            highlight SignColumn guibg=NONE
          endfunction

          " PaperColor
          let g:PaperColor_Theme_Options = {
          \   'theme': {
          \     'default': {
          \       'transparent_background': 1
          \     }
          \   }
          \ }
          colorscheme PaperColor

          " N.B. this augroup is explicitly after setting the default colorscheme.
          " Allowing this to run too early appears to interfere with ftdetect.
          augroup ReapplyHighlightGroups
            autocmd colorscheme * call s:reapplyHighlightGroups()
          augroup END
          function s:reapplyHighlightGroups()
            " Trigger refreshing syntax highlight groups for all buffers
            let current = bufnr()
            bufdo let &l:filetype = &l:filetype
            exec "buffer" current
          endfunction

          " Let other plugins (like lsp) draw over gitgutter signs.
          let g:gitgutter_sign_priority = 0

          " Enable extra highlighting features for Go (vim-go)
          let g:go_highlight_trailing_whitespace_error = 1
          let g:go_highlight_functions = 1
          let g:go_highlight_function_parameters = 1
          let g:go_highlight_function_calls = 1
          let g:go_highlight_types = 1
          let g:go_highlight_fields = 1
          let g:go_highlight_build_constraints = 1
          let g:go_highlight_generate_tags = 1
          let g:go_highlight_string_spellcheck = 1
          let g:go_highlight_format_strings = 1
          let g:go_highlight_variable_declarations = 1
          let g:go_highlight_variable_assignments = 1

          " More Go knobs
          let g:go_doc_popup_window = 1
          let g:go_doc_balloon = 1
          augroup GoFileKnobs
            autocmd BufNewFile,BufRead *.go call s:enableGoFileKnobs()
          augroup END

          function s:enableGoFileKnobs()
            setlocal mouse=a
            setlocal ttymouse=sgr
            setlocal balloonexpr=go#tool#DescribeBalloon()
            setlocal balloondelay=250
            setlocal balloonevalterm
          endfunction

          " mkdx
          let g:mkdx#settings = {
          \   'map': { 'prefix': '<Space>' }
          \ }

          " LSP for *.nix
          let s:lsp_exe_nix = '${lsp.nix-language-server}'
          let s:nixpkgs_fmt = '${nixpkgs-fmt}'
          if executable(s:lsp_exe_nix)
            autocmd User lsp_setup call lsp#register_server({
            \   'name': 'nil',
            \   'cmd': {server_info->[&shell, &shellcmdflag, s:lsp_exe_nix]},
            \   'allowlist': ['nix'],
            \ })
            if executable(s:nixpkgs_fmt)
              autocmd User lsp_setup call lsp#update_workspace_config('nil', {
              \   'nil': {
              \     'formatting': {
              \       'command': [s:nixpkgs_fmt],
              \     },
              \   },
              \ })
              autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled('*.nix')
            endif
          endif

          " LSP for *.yaml
          let s:lsp_exe_yaml = '${lsp.yaml-language-server}'
          if executable(s:lsp_exe_yaml)
            autocmd User lsp_setup call lsp#register_server({
            \   'name': 'yaml-language-server',
            \   'cmd': {server_info->[&shell, &shellcmdflag, s:lsp_exe_yaml . ' --stdio']},
            \   'allowlist': ['yaml'],
            \   'root_uri': {-> s:root_uri('.git')},
            \   'workspace_config': {
            \     'yaml': {
            \       'completion': v:true,
            \       'format': {
            \         'enable': v:true,
            \       },
            \       'hover': v:true,
            \       'schemas': {},
            \       'schemaStore': {
            \         'enable': v:true,
            \         'url': "",
            \       },
            \       'validate': v:true,
            \     },
            \   },
            \ })
            autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled('*.yaml')
          endif

          " LSP for *.json
          let s:lsp_exe_json = '${lsp.json-language-server}'
          if executable(s:lsp_exe_json)
            autocmd User lsp_setup call lsp#register_server({
            \   'name': 'vscode-json-language-server',
            \   'cmd': {server_info->[&shell, &shellcmdflag, s:lsp_exe_json . ' --stdio']},
            \   'allowlist': ['json'],
            \   'root_uri': {-> s:root_uri('.git')},
            \   'workspace_config': {
            \     'json': {
            \       'format': {
            \         'enable': v:true,
            \       },
            \       'schemas': {},
            \       'schemaStore': {
            \         'enable': v:true,
            \       },
            \     },
            \   },
            \ })
            autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled('*.json')
          endif

          " LSP helper function to find a reasonable filesystem root path for a project.
          function s:root_uri(...) abort
            function s:join(...) abort
              let sep = has('win32') ? '\' : '/'
              return join(map(copy(a:000), "substitute(v:val, '[/\\\\]\\+$', \"\", \"\")"), sep)
            endfunction
            let root = expand('%:p:h')
            let prev = ""
            while root !=# prev
              for name in a:000
                if getftype(s:join(root, name)) !=# ""
                  return lsp#utils#path_to_uri(root)
                endif
              endfor
              let prev = root
              let root = fnamemodify(root, ':h')
            endwhile
            return lsp#utils#get_default_root_uri()
          endfunction

          " Stuff to run when LSP is engaged for a buffer
          function s:on_lsp_buffer_enabled(matches)
            setlocal updatetime=250
            setlocal omnifunc=lsp#complete
            nmap <buffer> K <plug>(lsp-hover)
            let g:lsp_format_sync_timeout = 1000
            augroup LSPFormatOnSave
              autocmd!
              autocmd BufWritePre a:matches call execute('LspDocumentFormatSync')
            augroup END
          endfunction
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
