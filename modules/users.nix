{
  lib,
  config,
  ...
}: {
  # One entry per human who logs into any of your machines, e.g.
  # `users.mercury`. Each user gets four "buckets" to add config to,
  # from wherever in the tree is convenient:
  #
  #   nixos.base -> system-level config for this user (the users.users.*
  #                 account itself), included on every host that has them
  #   nixos.pc   -> system-level config only relevant on GUI machines
  #                 (imports nixos.base automatically)
  #   home.base  -> home-manager config for this user, everywhere
  #   home.gui   -> home-manager config only for GUI sessions
  #                 (imports home.base automatically)
  #
  # A host then simply does:
  #   imports = [ config.users.mercury.nixos.pc ];
  # and gets the account, its home-manager config, and everything any
  # module anywhere contributed to it — all in one line.
  options.users = lib.mkOption {
    default = {};
    type = lib.types.lazyAttrsOf (lib.types.submodule (userArgs @ {name, ...}: {
      options = {
        username = lib.mkOption {
          type = lib.types.str;
          default = name;
        };

        fullName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        # Set on first boot only; NixOS never touches the password again
        # after that, so `passwd` (or home-manager) is how you change it
        # for real. This exists so a freshly-imaged machine is usable
        # before you've set anything up. Change it on first login.
        initialPassword = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        nixos = {
          base = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
          };
          pc = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
          };
        };

        home = {
          base = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
          };
          gui = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
          };
        };
      };

      config = {
        nixos.base = {
          users.users.${userArgs.config.username} = {
            isNormalUser = true;
            description = lib.mkDefault (
              if userArgs.config.fullName == null
              then ""
              else userArgs.config.fullName
            );
            initialPassword = lib.mkIf (userArgs.config.initialPassword != null) userArgs.config.initialPassword;
            extraGroups = ["networkmanager"];
          };
          home-manager.users.${userArgs.config.username} = userArgs.config.home.base;
        };

        nixos.pc = {
          imports = [userArgs.config.nixos.base];
          users.users.${userArgs.config.username}.extraGroups = ["wheel"];
          home-manager.users.${userArgs.config.username} = userArgs.config.home.gui;
        };

        home.base = {
          imports = [config.homeManager.modules.base];
          home = {
            username = lib.mkDefault userArgs.config.username;
            homeDirectory = lib.mkDefault "/home/${userArgs.config.username}";
          };
        };

        home.gui.imports = [
          userArgs.config.home.base
          config.homeManager.modules.gui
        ];
      };
    }));
  };
}
