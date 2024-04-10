{
  description = "lrewega's MacBook Air";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1.0.tar.gz";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs = {
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

          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lrewega = import ./home.nix;
            home-manager.users.root = {
              programs.ssh = {
                enable = true;
                extraConfig = /* sshconfig */''
                  Host orb
                    HostName 127.0.0.1
                    Port 32222
                    User default
                    IdentityFile /Users/lrewega/.orbstack/ssh/id_ed25519
                    ProxyCommand env HOME=/Users/lrewega '/Applications/OrbStack.app/Contents/Frameworks/OrbStack Helper.app/Contents/MacOS/OrbStack Helper' ssh-proxy-fdpass 0
                    ProxyUseFdpass yes
                '';
              };
              home.stateVersion = "21.11";
            };
          }
        ];
        specialArgs = { inherit nixpkgs darwin home-manager flake-compat; };
      };          
    };
  };
}
