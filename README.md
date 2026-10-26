# MercDev

Declarative Nix configuration for MercDesk, MercLap, MercHome, and the planned MercServ/MercMac systems.

## Important status

This archive is a **configuration source package**, not a prebuilt NixOS system image. Nix is not installed in the editing environment, so the flake has not been evaluated or built here. Please evaluate it on a Nix-enabled machine before switching any host.

- `MercDesk` and `MercLap` are the active NixOS outputs.
- `mercury@MercHome` is a standalone Linux Home Manager profile.
- `MercServ` is intentionally not exposed as a flake output until the server hardware, boot method, architecture, and actual storage disk are known. Its service module is a draft and must be validated before enabling it.
- `MercMac` is intentionally disabled until the Apple Silicon Mac arrives.
- `flake.lock` includes the declared `nix-darwin` input. Run `nix flake check --show-trace` on a Nix-enabled machine before activation.

## Umbriel + Noctalia desktop

Umbriel is the shared compositor for both active NixOS desktops (`MercDesk` and `MercLap`) and the standalone Linux Home Manager profile (`MercHome`). It uses the dwindle layout, starts Noctalia, and is the default session in Noctalia Greeter. Niri and its generated configuration have been removed. MercMac is a disabled macOS target and MercServ remains an inactive headless homelab target.

Validate and build each active NixOS host before activation:

```sh
nix flake check --show-trace
nix eval .#nixosConfigurations.MercLap.config.system.build.toplevel.drvPath
sudo nixos-rebuild build --flake .#MercLap
```

After a successful build, confirm `umbriel.desktop` is available in the Wayland sessions directory, then review the build result before switching. Umbriel is a young, actively evolving compositor.

## First validation on MercDesk or MercLap

From the extracted `MercDev` directory:

```sh
nix flake lock
nix flake check --show-trace
nix eval .#nixosConfigurations.MercDesk.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.MercLap.config.system.build.toplevel.drvPath
```

If evaluation succeeds, inspect the diff and then build without activating:

```sh
sudo nixos-rebuild build --flake .#MercDesk
# or
sudo nixos-rebuild build --flake .#MercLap
```

Only after reviewing the result should you activate with `sudo nixos-rebuild switch --flake .#MercDesk` (or `MercLap`). Back up important data and keep a rollback path available.

## Tailscale

The NixOS daemon is enabled on MercDesk and MercLap. After deploying, enroll each machine interactively:

```sh
sudo tailscale up
 tailscale status
```

Do not store reusable Tailscale auth keys in this repository. Enable MagicDNS and review tailnet access controls in the Tailscale admin console. MercMac is not active; MercServ is not enabled as a flake output.

## Before deploying

- Replace the placeholder initial password `chloe` in `hosts/common/user.nix` with a secure credential strategy; preferably use a hashed password or another supported secret mechanism rather than a plaintext password.
- Confirm hardware-specific settings and generated `hardware-configuration.nix` files match the target machine.
- Restore actual wallpaper files under `Wallpapers/` if desired.
- MercLap is configured for an NVIDIA RTX 3050 Ti with the open kernel module.
- MercServ must have a real data-disk mount at `/srv/storage` before its services are enabled. Plan backups and permissions first; do not expose service ports to the public internet.
- KytyPS5 is a first-launch upstream source build and is experimental; use only software and game files you are authorized to use.
- iOS development on MercMac will require Apple's Xcode toolchain after the Mac arrives.

## Included functionality

- Umbriel + Noctalia dwindle-layout desktop on MercDesk, MercLap, and the standalone Linux MercHome profile. Ghostty, Nautilus, Firefox, Zed, Codex CLI, Rust toolchain, Flutter/Android tooling, JetBrainsMono Nerd Font.
- Tailscale on active Linux desktops.
- Discord on MercDesk/MercLap; macOS Discord/ChatGPT/Firefox/Tailscale casks are prepared in the disabled MercMac module.
- ProtonPlus and Steam on MercDesk only.
- MercServ draft homelab services: Jellyfin, qBittorrent, Immich, Audiobookshelf, Navidrome, Calibre-Web, and Samba. Not deployable until hardware/storage and module evaluation are complete.
