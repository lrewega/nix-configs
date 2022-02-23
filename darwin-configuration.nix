{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    iterm2
  ];

  # Configure /etc/shells to allow use of custom shell programs.
  environment.shells = with pkgs; [ bashInteractive bashInteractive_5 ];

  system.defaults = {
    # NSGlobalDomain = {
    #   NSWindowShouldDragOnGesture = true;
    # };

    finder = {
      AppleShowAllExtensions = true;
      QuitMenuItem = true;
      FXEnableExtensionChangeWarning = false;
      CreateDesktop = false;
    };

    loginwindow = {
      GuestEnabled = false;
    };
  };

  networking.hostName = "lrewega-MacBook-Air";

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nix = {
    package = pkgs.nixFlakes;

    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true
    '';

    # Use all cores.
    maxJobs = 8;
    buildCores = 8;
  };

  # Enable derivations for non-free software.
  nixpkgs.config = { allowUnfree = true; };

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;

  programs.vim = {
    enable = true;

    extraKnownPlugins = {
      vim-go = pkgs.vimUtils.buildVimPluginFrom2Nix {
        name = "vim-go";
        src = pkgs.fetchgit {
          url = "git://github.com/fatih/vim-go";
          rev = "abe94c3fcf681fde772f2906fbbdfecf5afda7c8";
          sha256 = "c34c15cf1d742db7a809e61c515e63170415446666077945547ecbb65b16b4b9";
        };
      };
    };

    plugins = [ { names = [
      "vim-fugitive"
      "vim-gitgutter"
      "vim-go"
    ]; } ];

    vimConfig = ''
      set relativenumber
      set hlsearch
    '';
  };

  # Address low ulimit defaults.
  launchd.daemons."limit-maxfiles".command = let
    softLimit = 32768; # 2^15
    hardLimit = 16777216; # 2^24
    in
      "launchctl limit maxfiles ${toString softLimit} ${toString hardLimit}";

  users.users.lrewega.home = "/Users/lrewega";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
