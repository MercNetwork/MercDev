{lib, ...}: {
  # Opt-in. Kept separate from arr-stack.nix (unlike sonarr/radarr/
  # prowlarr/bazarr, which are bundled) because someone might reasonably
  # want a Jellyfin media server *without* the automation stack, or vice
  # versa — that's a real, useful place to split.
  options.nixos.modules.jellyfin = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.jellyfin = {
    services.jellyfin.enable = true;

    # Hardware-accelerated transcoding needs GPU device access. The
    # driver side of that is a hardware module (see
    # modules/hardware/intel-arc.nix or modules/hardware/nvidia.nix);
    # this is the other half — letting the jellyfin user actually touch
    # /dev/dri.
    users.users.jellyfin.extraGroups = ["video" "render"];

    # Web UI: 8096. See modules/computers/mercserver.nix for the
    # firewall rule.
  };
}
