# TheMercNetwork

A from-scratch NixOS flake for **mercury**, using the **dendritic pattern**
(flake-parts + [import-tree](https://github.com/vic/import-tree)) and the
**COSMIC** desktop environment, modeled after
[mightyiam/infra](https://github.com/mightyiam/infra).

Three hosts:

| Host | Role | Notable modules |
| --- | --- | --- |
| `merclaptop` | laptop | NVIDIA (hybrid/Optimus) |
| `mercdesktop` | desktop | Intel Arc GPU |
| `mercserver` | headless media server | arr stack, qBittorrent, Jellyfin |

This repo lives at `/mercury/` on the host (rather than the conventional
`/etc/nixos`) — see the `nixos-rebuild` invocations below.

Read **[docs/SYNOPSIS.md](docs/SYNOPSIS.md)** first if you want to understand
*why* mightyiam/infra is built the way it is, and **[docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)**
for a hands-on walkthrough of this template and how to grow it into your own.

## Quick start

```sh
cd /mercury
git init
git add -A
nix flake update                            # pins nixvim (and any other new inputs) into flake.lock
nix flake check                             # evaluates everything, catches typos
sudo nixos-rebuild switch --flake /mercury#merclaptop    # or #mercdesktop / #mercserver
```

The first boot password for `mercury` is `Chloe` — change it immediately
with `passwd` after logging in.

Each host's `_*-hardware-configuration.nix` is currently a **placeholder**
(see the comment at the top of each). Replace it with the real output of
`sudo nixos-generate-config --show-hardware-config`, run on that machine,
before trying to build it for real.

## Layout

```
flake.nix                                  entry point, inputs, nixConfig
modules/
  nixos/base.nix                           the "every machine" bucket
  nixos/pc.nix                             the "every GUI machine" bucket
  nixos/configurations.nix                 host registry -> nixosConfigurations
  users.nix                                per-user account/home-manager registry
  home-manager.nix                         wires home-manager into every host
  nixpkgs.nix, nix-settings.nix            nixpkgs + nix daemon settings
  boot.nix, networking.nix, audio.nix,
  printing.nix, locale.nix                 small, single-purpose pc-level modules
  hardware/
    nvidia.nix                             opt-in NVIDIA module (merclaptop)
    intel-arc.nix                          opt-in Intel Arc GPU module (mercdesktop)
  services/
    arr-stack.nix                          opt-in Sonarr/Radarr/Prowlarr/Bazarr bundle
    jellyfin.nix                           opt-in Jellyfin
    qbittorrent.nix                        opt-in qBittorrent
  mercury/
    identity.nix                           username, full name, initial password
    desktop-environment.nix                COSMIC enable + greeter
    home.nix                               mercury's home-manager starting point
    proton.nix                             Proton Mail Bridge, Pass, VPN
    media.nix                              Spotify
    gaming.nix                             Steam + ProtonPlus
    discord.nix                            Discord
    winboat.nix                            WinBoat + Docker/KVM setup
    nixvim.nix                             Neovim (nixd/rust_analyzer/pyright/kotlin_language_server)
    fastfetch.nix                          minimal fastfetch (uptime + OS age)
    wallpapers.nix                         symlinks ~/Pictures/Wallpapers -> /mercury/wallpapers
  computers/
    merclaptop.nix                         MercLaptop host (NVIDIA)
    mercdesktop.nix                        MercDesktop host (Intel Arc)
    mercserver.nix                         MercServer host (headless media server)
    _merclaptop-hardware-configuration.nix real hardware scan
    _mercdesktop-hardware-configuration.nix   \_ placeholders — see Quick start above
    _mercserver-hardware-configuration.nix    /
wallpapers/                                 wallpaper images, symlinked into mercury's home
```
