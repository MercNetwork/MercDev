{ pkgs, ... }:
{
  imports = [
    ../common/desktop.nix
    ./hardware-configuration.nix
    ./intel-arc.nix
  ];

  networking.hostName = "MercDesk";
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [ protonplus ];
}
