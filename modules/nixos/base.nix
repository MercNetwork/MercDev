{lib, ...}: {
  # This declares a *bucket*, not a value. It's a `deferredModule`: a slot
  # that many separate files can each add a piece of NixOS config to, via
  # `config.nixos.modules.base = { ... }`. The module system merges every
  # contribution into one combined NixOS module. This is the core trick
  # that makes the dendritic pattern possible: instead of one long
  # configuration.nix, "base" ends up being built from a dozen small,
  # focused files (boot.nix, networking.nix, nix-settings.nix, ...), each
  # of which is free to add to it from wherever it lives in the tree.
  #
  # "base" = config every single NixOS machine gets, servers and
  # desktops alike.
  options.nixos.modules.base = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };
}
