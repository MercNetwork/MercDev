{ pkgs, ... }:
{
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt intel-compute-runtime ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  hardware.enableRedistributableFirmware = true;
  # Arc B570 is Battlemage/Xe2; do not force the legacy i915 GuC parameter.
}
