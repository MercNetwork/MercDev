{ pkgs, ... }:
{
  imports = [ ./user.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

  # Join this machine to the user's tailnet after deployment with `sudo tailscale up`.
  services.tailscale.enable = true;
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Umbriel + Noctalia Wayland desktop, shared by active Linux desktops.
  programs.umbriel.enable = true;
  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "umbriel";
      user.default = "mercury";
      keyboard.layout = "us";
      cursor.size = 24;
      cursor.theme = "Bibata-Modern-Ice";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
  };
  services.gvfs.enable = true;

  # Audio / printing
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Nerd Font preference across GTK/desktop applications. JetBrainsMono Nerd
  # Font is also selected for the emoji family as requested; emoji coverage is
  # not the same as a dedicated color-emoji font, so some glyphs may fall back.
  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
    fontconfig.defaultFonts = {
      serif = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "JetBrainsMono Nerd Font" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      emoji = [ "JetBrainsMono Nerd Font" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };

  # Shared desktop apps. ProtonPlus is intentionally host-specific to MercDesk.
  environment.systemPackages = with pkgs; [
    fastfetch
    git
    unzip
    unrar
    discord
    popsicle
    firefox
    android-tools
  ];

  system.stateVersion = "25.05";
}
