{ pkgs, ... }:
{
  imports = [ ../common/user.nix ];

  networking.hostName = "MercServ";
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  networking.networkmanager.enable = true;
  services.tailscale.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Homelab storage layout. IMPORTANT: before activating this host, configure
  # the actual data disk/filesystem at /srv/storage. The flake output remains
  # disabled until hardware and architecture are verified; do not deploy these
  # services without a real storage mount or media may fill the root filesystem.
  users.groups.media = { };
  users.users.mercury.extraGroups = [ "media" ];
  users.users.immich.extraGroups = [ "media" ];

  systemd.tmpfiles.rules = [
    "d /srv/storage 2770 root media -"
    "d /srv/storage/media 2770 root media -"
    "d /srv/storage/downloads 2770 qbittorrent media -"
    "d /srv/storage/downloads/incomplete 2770 qbittorrent media -"
    "d /srv/storage/books 2770 root media -"
    "d /srv/storage/audiobooks 2770 root media -"
    "d /srv/storage/music 2770 root media -"
    "d /srv/storage/photos 0700 immich immich -"
  ];

  # Self-hosted media streaming. Keep ports closed on LAN/WAN; only the
  # tailscale0 interface receives the app ports below.
  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = false;
  };

  # Headless qBittorrent. The Web UI is reachable only from the tailnet via
  # the interface-specific firewall rule below. Set a strong Web UI password
  # after first start; do not expose the UI to the public internet.
  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "media";
    webuiPort = 8080;
    openFirewall = false;
    serverConfig = {
      Downloads = {
        SavePath = "/srv/storage/downloads/";
        TempPath = "/srv/storage/downloads/incomplete/";
        TempPathEnabled = true;
      };
      WebUI.Address = "0.0.0.0";
    };
  };
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";

  # iCloud Photos replacement. The custom media directory must exist and be
  # owned by immich; tmpfiles creates it, and the real disk must be mounted first.
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = false;
    mediaLocation = "/srv/storage/photos";
  };

  # Audiobook/podcast library (Audiobookshelf) and ebook library (Calibre-Web).
  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 8000;
    group = "media";
    openFirewall = false;
  };

  # Personal music streaming alternative to a subscription music locker.
  services.navidrome = {
    enable = true;
    group = "media";
    openFirewall = false;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/srv/storage/music";
      EnableInsightsCollector = false;
    };
  };

  services.calibre-web = {
    enable = true;
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    group = "media";
    openFirewall = false;
    options.enableBookUploading = true;
    # Choose /srv/storage/books after creating the Calibre library in the UI.
    # Leaving calibreLibrary unset avoids failing the first boot before metadata.db exists.
  };

  # Simple private NAS share for files/media. Add an SMB password after the
  # first boot with `sudo smbpasswd -a mercury`; no guest access is allowed.
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    openFirewall = false;
    settings = {
      global = {
        "server string" = "MercServ";
        "workgroup" = "WORKGROUP";
        security = "user";
        "map to guest" = "never";
      };
      storage = {
        path = "/srv/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "mercury";
        "force group" = "media";
        "create mask" = "0660";
        "directory mask" = "2770";
      };
    };
  };

  # Restrict access to homelab web UIs and SMB to the private tailnet.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    445   # SMB / NAS
    4533  # Navidrome music streaming
    8000  # Audiobookshelf
    8080  # qBittorrent Web UI
    8083  # Calibre-Web
    8096  # Jellyfin
    2283  # Immich
  ];

  environment.systemPackages = with pkgs; [ fastfetch git ];
  system.stateVersion = "25.05";
}
