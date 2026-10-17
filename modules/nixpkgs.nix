{lib, ...}: {
  # Applies to every host's NixOS-level nixpkgs instance. `home-manager`
  # is told (in modules/home-manager.nix) to reuse this same instance via
  # `useGlobalPkgs`, so there's exactly one nixpkgs evaluation per host,
  # not two.
  nixos.modules.base = {
    nixpkgs.config.allowUnfree = lib.mkDefault true;
  };
}
