{
  description = "lrewega's MacBook Air";

  inputs = {
    # Temporarily use a revision excluding https://github.com/NixOS/nixpkgs/pull/241692 until addressed
    # Selected arbitrarily via https://github.com/NixOS/nixpkgs/activity?ref=nixos-unstable and verifying a cache hit
    nixpkgs.url = "github:NixOS/nixpkgs/5e4c2ada4fcd54b99d56d7bd62f384511a7e2593";
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    darwin,
    home-manager,
    flake-compat,
    ...
  }: {
    darwinConfigurations = {
      lrewega-MacBook-Pro = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin-configuration.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lrewega = import ./home.nix;
          }
        ];
        specialArgs = { inherit nixpkgs darwin home-manager flake-compat; };
      };          
    };
  };
}
