{config, ...}: {
  nixos.configurations.mercdesktop.module = {
    imports = [
      # Real, machine-specific hardware scan — placeholder for now. See
      # ./_mercdesktop-hardware-configuration.nix for what to replace it
      # with (run `sudo nixos-generate-config --show-hardware-config` on
      # the desktop itself).
      ./_mercdesktop-hardware-configuration.nix

      # Everything a GUI machine gets (boot, audio, networking, locale,
      # COSMIC, home-manager wiring, ...).
      config.nixos.modules.pc

      # mercury's account, desktop, and home-manager config.
      config.users.mercury.nixos.pc

      # MercDesktop has an Intel Arc GPU.
      config.nixos.modules.intel-arc
    ];

    # Set once, at first install, and then never changed. See
    # modules/nix-settings.nix for why this isn't a shared default.
    system.stateVersion = "26.05";

    time.timeZone = "America/Chicago";
  };
}
