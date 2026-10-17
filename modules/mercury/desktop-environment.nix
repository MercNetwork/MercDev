{
  # COSMIC (System76's Rust-based desktop environment) + its own
  # greeter. Swapped back from niri + DankMaterialShell after DMS's Nix
  # packaging proved too much of a moving target for daily use — see
  # docs/BUILD_GUIDE.md for the debugging trail that led here, if
  # niri + DMS is ever worth revisiting once that packaging settles.
  users.mercury.nixos.pc = {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    # A generically useful responsiveness scheduler on any modern
    # desktop, not actually COSMIC-specific, but shipped by System76
    # and typically enabled alongside COSMIC.
    services.system76-scheduler.enable = true;
  };
}
