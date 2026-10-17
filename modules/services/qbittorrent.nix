{lib, ...}: {
  # Opt-in. Split from arr-stack.nix for the same reason jellyfin.nix is:
  # a real, independent decision (which download client, if any) rather
  # than something always bundled together.
  options.nixos.modules.qbittorrent = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.qbittorrent = {
    services.qbittorrent = {
      enable = true;
      # Runs as its own dedicated `qbittorrent` system user by default.
      # webuiPort defaults to 8080 — see modules/computers/mercserver.nix
      # for the firewall rule that exposes it.
    };
  };
}
