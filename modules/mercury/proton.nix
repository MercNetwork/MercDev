{
  # Proton stack. Lives in home.gui (not nixos.pc) since these are all
  # per-user GUI applications, not system services — same reasoning as
  # cosmic-files/kitty/nautilus in modules/mercury/home.nix.
  users.mercury.home.gui = {pkgs, ...}: {
    home.packages = with pkgs; [
      # There's no official Proton Mail *desktop* client in nixpkgs yet
      # (the upstream app is still a Linux beta .deb — see
      # nixpkgs#296107, still open). Mail is handled instead the
      # supported way: the Bridge exposes a local IMAP/SMTP endpoint
      # that any real mail client authenticates against.
      protonmail-desktop

      proton-pass # password manager

      proton-vpn # official Proton VPN GUI client — this package was
      # renamed from `protonvpn-gui`; if you're pinned to an older
      # nixpkgs channel, use `protonvpn-gui` instead.
    ];

    # No mail client is installed here on purpose — wire the Bridge's
    # local IMAP/SMTP into whichever one you actually want (Thunderbird,
    # etc.) once it's running and you've logged in once interactively.
  };
}
