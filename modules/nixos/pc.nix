{
  lib,
  config,
  ...
}: {
  # "pc" = config only for machines that have a display and a human
  # sitting in front of them (as opposed to e.g. a headless server).
  # It automatically includes "base" by importing it, so a pc gets
  # everything a base machine gets, plus GUI-specific stuff layered on.
  options.nixos.modules.pc = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
  };

  config.nixos.modules.pc.imports = [config.nixos.modules.base];
}
