{lib, ...}: {
  # Opt-in, same pattern as modules/hardware/nvidia.nix, but for a
  # *service* bundle instead of a piece of hardware: Sonarr (TV),
  # Radarr (movies), Prowlarr (indexer manager), and Bazarr (subtitles).
  #
  # These four are unified into a single named module rather than four
  # separate ones (contrast with jellyfin.nix / qbittorrent.nix getting
  # their own toggles): in practice they're only ever meaningfully used
  # together — Prowlarr exists to feed Sonarr/Radarr, and Bazarr exists
  # to follow up behind them — so splitting them wouldn't buy any host
  # the ability to opt out of just one piece in a useful way. That's the
  # same test mightyiam/infra applies when deciding whether a set of
  # option values deserves its own distinct named module.
  #
  # A host that wants this bundle adds:
  #   imports = [ config.nixos.modules.arr-stack ];
  options.nixos.modules.arr-stack = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.arr-stack = {
    services.sonarr.enable = true;
    services.radarr.enable = true;
    services.prowlarr.enable = true;
    services.bazarr.enable = true;

    # Each *arr service defaults to its own dedicated system user/group
    # (sonarr/radarr/prowlarr/bazarr) and opens no firewall ports itself.
    # See modules/computers/mercserver.nix for the ports this bundle
    # actually needs exposed:
    #   Sonarr 8989 · Radarr 7878 · Prowlarr 9696 · Bazarr 6767
  };
}
