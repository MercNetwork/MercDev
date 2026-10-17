{
  users.mercury = {
    nixos.pc = {pkgs, ...}: {
      # System-wide Firefox (as opposed to a home-manager-managed one)
      # so it's available even before home-manager has run.
      programs.firefox.enable = true;
      environment.systemPackages = [pkgs.vim pkgs.wget pkgs.git];
    };

    home.gui = {pkgs, ...}: {
      # cosmic-files/cosmic-term: COSMIC's own file manager and
      # terminal, native to the desktop environment now back in use
      # (see modules/mercury/desktop-environment.nix). kitty/nautilus
      # were a DE-agnostic stand-in during the niri + DMS experiment —
      # switched back now that COSMIC's own apps are the better fit.
      home.packages = [pkgs.cosmic-files pkgs.cosmic-term];

      # This is the seam where you'll add everything that actually makes
      # the system "yours" once you're past the bootstrap stage: shell,
      # git config, terminal, editor, dotfiles, etc. See
      # modules/mercury/ in mightyiam/infra for how far this can go.
    };
  };
}
