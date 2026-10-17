{
  users.mercury.home.gui = {pkgs, ...}: {
    # Unfree; already allowed globally by modules/nixpkgs.nix.
    home.packages = [pkgs.spotify];
  };
}
