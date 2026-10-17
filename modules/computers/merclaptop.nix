{config, ...}: {
  nixos.configurations.merclaptop.module = {
    imports = [
      # The real, machine-specific hardware scan. Never hand-edit this —
      # if the disk layout or kernel modules change, re-run
      # `sudo nixos-generate-config --show-hardware-config` on the
      # laptop itself and paste the new output back in here.
      ./_merclaptop-hardware-configuration.nix

      # Everything a GUI machine gets: boot, audio, networking, locale,
      # nix settings, home-manager wiring, etc. — assembled from every
      # module in the tree that contributes to nixos.modules.pc.
      config.nixos.modules.pc

      # mercury's account, COSMIC desktop, and home-manager config —
      # assembled from every module that contributes to
      # users.mercury.nixos.pc.
      config.users.mercury.nixos.pc

      # MercLaptop has an NVIDIA GPU.
      config.nixos.modules.nvidia
    ];

    # Set once, at first install, and then never changed. See
    # modules/nix-settings.nix for why this isn't a shared default.
    system.stateVersion = "26.05";

    time.timeZone = "America/Chicago";
  };
}
