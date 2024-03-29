{ nixpkgs, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    iterm2
  ];

  # Configure /etc/shells to allow use of custom shell programs.
  environment.shells = with pkgs; [ bashInteractive bashInteractive_5 ];

  # via shasum -a 256 /etc/shells
  environment.etc.shells.knownSha256Hashes = [
    "9d5aa72f807091b481820d12e693093293ba33c73854909ad7b0fb192c2db193"
  ];

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

  # services = {
  #   postgresql = {
  #     enable = true;
  #     package = pkgs.postgresql;
  #     dataDir = "/usr/local/var/postgres";
  #   };
  # };

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      go-font
      source-code-pro
    ];
  };

  networking.hostName = "lrewega-MacBook-Pro";

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nix = {
    package = pkgs.nixFlakes;
    useDaemon = true;
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
      keep-derivations = true
      keep-outputs = true
    '';
    settings = {
      bash-prompt-prefix = "(nix:$name)\\040";
      max-jobs = "auto";
      extra-nix-path = "nixpkgs=flake:nixpkgs";
      extra-trusted-substituters = [
        "https://cache.floxdev.com"
        "https://cache.flox.dev"
      ];
      extra-trusted-public-keys = [
        "flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0=" # cache.floxdev.com
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=" # cache.flox.dev
      ];
    };
    registry = {
      # Expose the inputs to this very flake.
      local.flake = nixpkgs;
      # A rolling weekly unstable courtesy of detsys' flakehub
      nixpkgs.to = {
        type = "tarball";
        url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1.0.tar.gz";
      };
      # Make regular nixpkgsaccessible.
      nixpkgs-upstream = {
        exact = false;
        to = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
        };
      };
    };
  };

  # Enable derivations for non-free software.
  nixpkgs.config = { allowUnfree = true; };

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;

  # Address low ulimit defaults.
  launchd.daemons."limit-maxfiles".command =
    let
      softLimit = 32768; # 2^15
      hardLimit = 16777216; # 2^24
    in
    "launchctl limit maxfiles ${toString softLimit} ${toString hardLimit}";

  users.users.lrewega.home = "/Users/lrewega";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
