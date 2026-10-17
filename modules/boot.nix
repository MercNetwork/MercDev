{lib, ...}: {
  # Reasonable default for a modern EFI laptop/desktop. A host that boots
  # differently (BIOS/GRUB, a server, etc.) overrides these with
  # `lib.mkForce` in its own file.
  nixos.modules.pc = {pkgs, ...}: {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };
}
