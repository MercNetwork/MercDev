{
  lib,
  config,
  inputs,
  ...
}: {
  # This is the "host registry". Every machine you own gets one entry
  # here, e.g. `nixos.configurations.merclaptop`. You never call
  # `nixpkgs.lib.nixosSystem` yourself in a host file — you just hand
  # this option a `module` (a deferredModule, so `imports = [...]` works
  # fine) and it does the wiring for you, then publishes the result as
  # a normal `nixosConfigurations.<name>` flake output, exactly as if
  # you'd written it by hand.
  options.nixos.configurations = lib.mkOption {
    default = {};
    type = lib.types.lazyAttrsOf (lib.types.submodule (hostArgs @ {name, ...}: {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          default = "x86_64-linux";
          description = "The `system` string for this host, e.g. x86_64-linux.";
        };

        module = lib.mkOption {
          type = lib.types.deferredModule;
          default = {};
          description = "The NixOS module tree for this host.";
        };

        configuration = lib.mkOption {
          type = lib.types.unspecified;
          readOnly = true;
          description = "The realized `nixosSystem` result. Set automatically.";
          default = inputs.nixpkgs.lib.nixosSystem {
            inherit (hostArgs.config) system;
            specialArgs = {inherit inputs;};
            modules = [
              hostArgs.config.module
              {networking.hostName = lib.mkDefault name;}
            ];
          };
        };
      };
    }));
  };

  config.flake = {
    nixosConfigurations =
      config.nixos.configurations
      |> lib.mapAttrs (_: host: host.configuration);

    checks = lib.mkMerge (
      config.nixos.configurations
      |> lib.mapAttrsToList (name: host: {
        ${host.system}."nixosConfigurations/${name}" = host.configuration.config.system.build.toplevel;
      })
    );
  };
}
