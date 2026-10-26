# MercDev changelog and validation notes

## Current configuration

- Project renamed from MercRing to MercDev.
- Host directory mapping: Malenia -> MercDesk; Radahn -> MercLap; Mohg -> MercMac; Godrick -> MercServ; Morgott -> MercHome.
- Linux username: `mercury`; active NixOS hostnames: `MercDesk`, `MercLap`.
- MercDesk: Intel Arc B570; Umbriel + Noctalia; Steam and ProtonPlus enabled here only.
- MercLap: NVIDIA GeForce RTX 3050 Ti (Ampere), NVIDIA open kernel module enabled.
- MercMac: Apple Silicon (`aarch64-darwin`) configuration prepared but Darwin flake output remains commented out until the device arrives.
- MercHome: standalone Home Manager profile on x86_64-linux.
- Tailscale: enabled as a NixOS daemon on MercDesk/MercLap; prepared on MercServ; Tailscale CLI included in Home Manager, and the Tailscale macOS app cask is prepared for MercMac (still disabled). Each device must authenticate interactively with the user's tailnet.
- MercServ homelab scaffold: Jellyfin, qBittorrent-nox, Immich, Audiobookshelf, Navidrome, Calibre-Web, and a private Samba share; service ports are allowed only on `tailscale0`. Storage paths are under `/srv/storage`. MercServ remains inactive until its architecture/hardware and actual data-disk mount are confirmed.
- KytyPS5: MercDesk-only first-launch helper clones the upstream source, builds the launcher using the upstream Nix development shell, then launches it. First build requires network access and can take a while; emulator compatibility/performance varies.
- Desktop: Umbriel (dwindle layout), Noctalia, Noctalia Greeter, Ghostty, Nautilus, Firefox, Zed.
- Browser: Firefox only; Zen Browser removed.
- Discord: installed on MercDesk and MercLap; prepared as a Homebrew cask on MercMac.
- ChatGPT: Linux desktop launcher opens the official web app in Firefox; macOS ChatGPT cask prepared for MercMac. Native ChatGPT Linux app preview supports specific Ubuntu/Debian/Fedora/Arch releases, not NixOS, so the Linux entry intentionally uses Firefox.
- OpenAI Codex CLI: added as a Nix package to the shared Home Manager environment, with an Umbriel shortcut and desktop launcher on Linux. On MercDesk and MercLap, run `codex` in a terminal and authenticate using “Sign in with ChatGPT”.
- Fonts: JetBrainsMono Nerd Font is the sole configured font family, including the fontconfig emoji preference. Nerd Fonts are patched icon fonts, not full color emoji fonts; some emoji may fall back or render monochromatically.
- Development: Zed, nixd, Rust toolchain, Flutter/Android Studio/Android tools/JDK on Linux.
- MercLap RTX 3050 Ti supports NVIDIA's open kernel module generation requirement (Turing or newer).
- Initial password remains `chloe` by user request; replace before deploying.
- Wallpaper directory preserved as `Wallpapers/.keep`; original wallpaper image files were not in the uploaded archive.

## Global Umbriel migration (2026-10-25)

- Enabled `programs.umbriel.enable = true` in `hosts/common/desktop.nix`, applying Umbriel to the active NixOS desktop hosts MercDesk and MercLap.
- Set the Noctalia Greeter default session to `umbriel`.
- Made the declarative `~/.config/umbriel/config.toml` available to all Linux Home Manager profiles, including standalone MercHome, using the dwindle layout, 8px gap, US keyboard layout, 24px cursor, Noctalia autostart, and the existing application/workspace/control shortcuts.
- Removed Niri from Home Manager packages, removed the generated `niri/config.kdl`, and removed `programs.niri` settings. The old Niri configuration is no longer retained as a fallback.
- MercMac remains disabled because its Apple Silicon machine has not arrived; MercServ remains inactive as a headless homelab target. Umbriel is Linux-only.
- Static archive checks only. Nix evaluation, system builds, and live session validation still need to be run on a Nix-enabled target; no activation was performed here.
- Initial password configuration remains unchanged pending a separate SOPS migration. Keep the archive/repository private until credentials are removed from tracked configuration.

## Validation status

- Source changes have not been evaluated by Nix in this environment because `nix` is not installed here.
- `flake.lock` contains nixpkgs, Home Manager, and nix-darwin. Refresh inputs only deliberately; this package has not been evaluated with Nix in this editing environment.
- The native ChatGPT Linux desktop preview is not formally supported on NixOS; Linux uses a Firefox desktop launcher instead.
- MercMac is intentionally disabled; do not enable its Darwin output until the Apple Silicon Mac arrives and the Homebrew/nix-darwin configuration is tested.
- MercServ is intentionally disabled. Before activation, create/import a hardware configuration, verify the CPU architecture/boot method, configure `/srv/storage` as a real data-disk mount, and review backups/permissions. Do not expose the service ports on WAN/LAN; only the Tailscale interface is allowed. Set qBittorrent and application credentials after first login.
- Tailscale is not automatically enrolled into the account by Nix: on each deployed device run `sudo tailscale up` (NixOS) or finish the platform app setup and sign in. Do not put reusable auth keys in the flake. Configure tailnet ACLs/MFA in the Tailscale admin console.
- MercServ SMB requires `sudo smbpasswd -a mercury` after deployment. Calibre-Web needs a Calibre library created and selected in its setup UI.
- Run `nix flake check`, `nix eval .#nixosConfigurations.MercDesk.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.MercLap.config.system.build.toplevel.drvPath`, and `umbriel config validate` on a Nix-enabled target after updating the lockfile.

## Packaging notes (2026-10-23)

- Added `README.md` with validation/build commands and deployment caveats.
- Adjusted the optional MercDesk-only KytyPS5 desktop entry to use an explicit conditional attribute set.
- No NixOS derivation was built in this environment (`nix`/`nix-instantiate` are not installed). The deliverable is the source configuration archive for testing on a Nix-enabled machine.
