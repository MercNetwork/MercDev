{lib, ...}: {
  nixos.modules.pc = {
    services.printing.enable = lib.mkDefault false;
  };
}
