{lib, ...}: {
  # Opt-in: a host that has an NVIDIA GPU adds
  #   imports = [ config.nixos.modules.nvidia ];
  # to its own module. Hosts without an NVIDIA GPU simply never import
  # this, and pay nothing for it. This is the same content as the
  # original nvidia.nix, just turned into a reusable named piece instead
  # of a file you'd have to remember to import by hand everywhere.
  options.nixos.modules.nvidia = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.nvidia = {config, ...}: {
    hardware.graphics.enable = true;

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;

      # Experimental; can break suspend/sleep. Flip on if you know your
      # hardware handles it well.
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      # The open-source kernel module only supports Turing and later.
      open = false;

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # MercLaptop's hardware scan loads `kvm-intel`, meaning it also has
      # Intel CPU graphics — this is very likely a hybrid "Optimus"
      # laptop (Intel iGPU + NVIDIA dGPU), not a desktop with only an
      # NVIDIA card. Hybrid laptops need `prime` configured or the NVIDIA
      # GPU either won't be used at all, or will be on 100% of the time
      # and drain the battery fast. Find your two bus IDs with:
      #
      #   lspci | grep -E 'VGA|3D'
      #
      # which prints two lines like:
      #   00:02.0 VGA compatible controller: Intel Corporation ...
      #   01:00.0 3D controller: NVIDIA Corporation ...
      # Turn "00:02.0" into "PCI:0:2:0" and "01:00.0" into "PCI:1:0:0",
      # then uncomment and fill in:
      #
      # prime = {
      #   intelBusId = "PCI:0:2:0";
      #   nvidiaBusId = "PCI:1:0:0";
      #
      #   # Offload mode: iGPU drives the display always, NVIDIA wakes
      #   # only for apps you explicitly launch with
      #   # `nvidia-offload <command>`. Best battery life — good default
      #   # for a laptop. Swap for `sync.enable = true;` instead if you
      #   # want the dGPU driving the display full-time (better
      #   # performance, worse battery).
      #   offload = {
      #     enable = true;
      #     enableOffloadCmd = true;
      #   };
      # };
    };
  };
}
