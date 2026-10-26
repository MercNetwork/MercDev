{
  description = "MercDev multi-system configuration (NixOS unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Prepared for MercMac, but the Darwin output remains disabled until the
    # Apple Silicon device arrives and can be tested.
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }:
    let
      mkHost = { hostPath, hostName, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit hostName; };
          modules = [
            hostPath
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mercury = import ./home.nix;
              home-manager.extraSpecialArgs = { inherit hostName; };
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
    in {
      nixosConfigurations = {
        MercDesk = mkHost { hostPath = ./hosts/MercDesk/default.nix; hostName = "MercDesk"; };
        MercLap = mkHost { hostPath = ./hosts/MercLap/default.nix; hostName = "MercLap"; };

        # Inactive until target hardware, architecture, boot and /srv/storage disk mount are verified.
        # The host module contains the homelab service plan but must not be deployed before storage is mounted.
        # MercServ = mkHost { hostPath = ./hosts/MercServ/default.nix; hostName = "MercServ"; system = "aarch64-linux"; };
      };

      # Standalone Linux Home Manager profile.
      homeConfigurations."mercury@MercHome" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        extraSpecialArgs = { hostName = "MercHome"; };
        modules = [ ./home.nix ];
      };

      # MercMac is intentionally DISABLED for now. Uncomment only after the
      # Apple Silicon Mac arrives and the macOS configuration is tested.
      # darwinConfigurations.MercMac = nix-darwin.lib.darwinSystem {
      #   system = "aarch64-darwin";
      #   modules = [
      #     ./hosts/MercMac/default.nix
      #     home-manager.darwinModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs = true;
      #       home-manager.useUserPackages = true;
      #       home-manager.users.mercury = import ./home.nix;
      #       home-manager.extraSpecialArgs = { hostName = "MercMac"; };
      #     }
      #   ];
      # };
    };
}
