{ ... }:
{
  imports = [
    ../common/desktop.nix
    ./hardware-configuration.nix
    ./nvidia.nix
  ];
  networking.hostName = "MercLap";
  nixpkgs.config.nvidia.acceptLicense = true;

}
