{lib, ...}: {
  # Opt-in, same idea as modules/hardware/nvidia.nix: a host with a
  # discrete Intel Arc GPU (or any Xe/Arc-generation Intel graphics) adds
  #   imports = [ config.nixos.modules.intel-arc ];
  # to its own module. Hosts without one simply never import this, and
  # pay nothing for it.
  options.nixos.modules.intel-arc = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.intel-arc = {pkgs, ...}: {
    # Arc needs no proprietary driver — Mesa's "modesetting" X driver
    # plus the packages below cover display, Vulkan/OpenGL, and VA-API.
    services.xserver.videoDrivers = ["modesetting"];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # VA-API (iHD backend). Required — the older intel-vaapi-driver
        # (i965) doesn't know about Xe/Arc-generation hardware at all.
        intel-media-driver

        # oneVPL (Quick Sync) runtime; the modern replacement for
        # onevpl-intel-gpu / intel-media-sdk on current nixpkgs. Needed
        # for hardware video encode (e.g. Jellyfin/Plex transcoding,
        # OBS, ffmpeg -hwaccel qsv).
        vpl-gpu-rt

        # OpenCL + oneAPI Level Zero compute. Not required just to get a
        # display or media playback working, but cheap to include and
        # needed by anything that wants GPU compute (e.g. some ML/CV
        # tooling, Blender's oneAPI backend).
        intel-compute-runtime
      ];
    };

    # Prefer the modern iHD VA-API backend explicitly, rather than
    # relying on libva's own auto-detection.
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    # Anecdotally helps VA-API/Quick Sync initialization on some Arc +
    # i915 combinations. Harmless if the hardware doesn't need it.
    boot.kernelParams = ["i915.enable_guc=3"];

    hardware.enableRedistributableFirmware = true;

    # If a *server* (headless) host ever imports this instead of a GUI
    # one — e.g. to give Jellyfin hardware transcoding — remember the
    # service's user also needs `extraGroups = [ "video" "render" ];`.
    # See modules/services/jellyfin.nix, which already does this.
  };
}
