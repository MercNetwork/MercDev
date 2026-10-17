{
  nixos.modules.base = {
    nix.settings = {
      experimental-features = ["nix-command" "flakes" "pipe-operators"];
      warn-dirty = false;
    };

    # Keeps the store from growing forever.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    nix.optimise.automatic = true;
  };

  # NOTE: `system.stateVersion` is deliberately NOT set here. It's a
  # per-host, set-once-at-first-install value (see the NixOS manual) —
  # it belongs in each host's own file (see modules/computers/merclaptop.nix),
  # never in a shared default.
}
