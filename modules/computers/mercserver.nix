{config, ...}: {
  nixos.configurations.mercserver.module = {pkgs, ...}: {
    imports = [
      # Real, machine-specific hardware scan — placeholder for now. See
      # ./_mercserver-hardware-configuration.nix for what to replace it
      # with (run `sudo nixos-generate-config --show-hardware-config` on
      # the server itself).
      ./_mercserver-hardware-configuration.nix

      # Headless: everything every machine gets (boot, networking,
      # nix settings, home-manager wiring, ...) — but *not*
      # nixos.modules.pc, since there's no display or human sitting in
      # front of this one. No COSMIC, no GUI packages.
      config.nixos.modules.base

      # mercury still gets an account (for SSH/admin), just the
      # system-level-only bucket — no GUI home-manager config pulled in.
      config.users.mercury.nixos.base

      # The media stack.
      config.nixos.modules.arr-stack
      config.nixos.modules.jellyfin
      config.nixos.modules.qbittorrent
    ];

    system.stateVersion = "26.05";
    time.timeZone = "America/Chicago";
    i18n.defaultLocale = "en_US.UTF-8"; # set explicitly: nixos.modules.pc
    # defaults this, but this host doesn't import pc, only base.

    # Same story as i18n.defaultLocale above: boot.nix's defaults live
    # under nixos.modules.pc ("reasonable default for a modern EFI
    # laptop/desktop"), which this headless host doesn't import. Assumed
    # EFI here too — swap for boot.loader.grub if this box is BIOS/MBR.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # A server needs networkmanager and rtkit/pipewire (both defined
    # under nixos.modules.pc, which this host doesn't import) about as
    # much as it needs a desktop environment — i.e. not at all. Plain
    # networkd/DHCP is enough for a wired box; override here if this
    # server actually needs something fancier (bonding, VLANs, etc.).
    networking.useDHCP = true;

    networking.firewall.allowedTCPPorts = [
      8989 # Sonarr
      7878 # Radarr
      9696 # Prowlarr
      6767 # Bazarr
      8096 # Jellyfin
      8080 # qBittorrent WebUI
    ];
  };
}
