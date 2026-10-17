{
  inputs,
  lib,
  config,
  ...
}: {
  # Same bucket idea as nixos.modules.base/pc, but for home-manager
  # (per-user, user-level config: dotfiles, shell, GUI apps, ...).
  # "base" = every user gets this. "gui" = users who log into a desktop
  # session get this too (imports base automatically).
  options.homeManager.modules = {
    base = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
    gui = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };

  config = {
    homeManager.modules = {
      base.programs.home-manager.enable = true;
      gui.imports = [config.homeManager.modules.base];
    };

    # Every NixOS host gets the home-manager NixOS module wired in, using
    # the same nixpkgs the system uses (so you don't end up with two
    # copies of nixpkgs evaluated).
    nixos.modules.base = {
      imports = [inputs.home-manager.nixosModules.home-manager];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";

        sharedModules = [
          ({osConfig, ...}: {
            home.stateVersion = osConfig.system.stateVersion;
          })
        ];
      };
    };
  };
}
