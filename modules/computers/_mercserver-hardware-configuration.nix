# PLACEHOLDER — this is not a real hardware scan.
#
# Replace this entire file with the real output of, run on mercserver
# itself:
#
#   sudo nixos-generate-config --show-hardware-config > /mercury/modules/computers/_mercserver-hardware-configuration.nix
#
# Until then, this file's UUIDs, device names, and detected kernel
# modules are all made up and building this host will not produce a
# bootable system.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["nvme" "ahci" "xhci_pci" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000003";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0001-0001";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  # A media/server box benefits from real swap or none at all depending
  # on RAM; left empty here rather than guessing.
  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
