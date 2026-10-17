{
  # Steam needs to be a system-level program (`programs.steam`, not a
  # home-manager package) because it installs setuid wrappers and pulls
  # in FHS-compatible sandboxing — a plain `home.packages = [pkgs.steam]`
  # would run, but miss the parts of the module that make most games
  # actually work.
  users.mercury.nixos.pc = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Steam (and most Proton/Wine-based tools) need 32-bit graphics
    # libraries alongside the 64-bit ones already enabled by whichever
    # GPU module a given host imports (nvidia.nix / intel-arc.nix).
    hardware.graphics.enable32Bit = true;
  };

  # ProtonPlus: a GTK4 GUI for managing Proton-GE/Wine-GE/DXVK/VKD3D
  # versions across Steam, Lutris, Heroic, and Bottles — the actual
  # "protonplus" package name in nixpkgs. A per-user GUI app, so it
  # lives in home.gui rather than alongside Steam's system-level config.
  users.mercury.home.gui = {pkgs, ...}: {
    home.packages = [pkgs.protonplus];
  };
}
