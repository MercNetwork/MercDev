{ config, pkgs, lib, hostName ? "MercHome", ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # KytyPS5 currently publishes a Nix development shell, not a ready-to-install
  # Nix package. On first launch this helper clones upstream and builds inside
  # the project's documented Nix shell.
  kytyps5Bind = if hostName == "MercDesk" then "Mod+Shift+P { spawn \"kytyps5\"; }" else "";

  kytyps5Launcher = pkgs.writeShellApplication {
    name = "kytyps5";
    runtimeInputs = with pkgs; [ git nix coreutils ];
    text = ''
      repo="$HOME/Applications/KytyPS5"
      launcher="$repo/_Build/linux/install/kyty_launcher"

      if [ ! -x "$launcher" ]; then
        mkdir -p "$(dirname "$repo")"

        if [ ! -d "$repo/.git" ]; then
          git clone --recurse-submodules \
            https://github.com/KytyPS5/KytyPS5.git "$repo"
        fi

        # Configure and build within KytyPS5's own development environment.
        # shellcheck disable=SC2016
        nix develop "$repo" --command bash -c '
          set -euo pipefail
          cd "$1"
          git submodule update --init --recursive
          cmake -S . -B _Build/linux -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER=clang++
          cmake --build _Build/linux --target launcher --parallel
          cmake --install _Build/linux --prefix _Build/linux/install
        ' kytyps5-build "$repo"
      fi

      # The emulator also needs the development shell's runtime libraries.
      cd "$repo"
      exec nix develop "$repo" --command "$launcher" "$@"
    '';
  };

in {
  home.username = "mercury";
  home.homeDirectory = if isDarwin then "/Users/mercury" else "/home/mercury";
  home.stateVersion = "25.05";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "eza -l";
      update = if isDarwin
        then "darwin-rebuild switch --flake .#MercMac"
        else if hostName == "MercHome"
          then "home-manager switch --flake .#mercury@MercHome"
          else "sudo nixos-rebuild switch --flake .#${hostName}";
      garbage = "nix-collect-garbage -d";
      gs = "git status";
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
      chatgpt = if isLinux then "firefox --new-window https://chatgpt.com" else "open -a ChatGPT";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Hunter Welch";
      email = "hxnterwelch@icloud.com";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  home.packages = with pkgs; [
    # OpenAI Codex CLI: run `codex` from any project directory.
    codex

    # Rust and native development
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    pkg-config

    # Nix tooling
    nixd

    # CLI utilities
    eza
    bat
    python3
    ripgrep
    fzf
  ]
  ++ lib.optionals isLinux [
    gcc
    umbriel
    noctalia
    ghostty
    nautilus
    firefox
    flutter
    android-studio
    android-tools
    jdk17
    tailscale
  ]
  ++ lib.optionals (isLinux && hostName == "MercDesk") [ kytyps5Launcher ];

  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "rust" "dart" "toml" "json" "yaml" ];
    userSettings = {
      theme = "One Dark";
      ui_font_size = 16;
      buffer_font_size = 14;
      languages = {
        Nix = { language_servers = [ "nixd" ]; };
        Rust = { language_servers = [ "rust-analyzer" ]; };
      };
    };
    extraPackages = with pkgs; [ nixd rust-analyzer ];
  };

  # Linux ChatGPT desktop entry uses the official ChatGPT web experience in
  # Firefox. OpenAI's native Linux desktop app preview currently targets
  # specific Ubuntu/Debian/Fedora/Arch releases, not NixOS.
  xdg.desktopEntries = lib.mkIf isLinux ({
    chatgpt = {
      name = "ChatGPT";
      comment = "Open ChatGPT in Firefox";
      exec = "${pkgs.firefox}/bin/firefox --new-window https://chatgpt.com";
      terminal = false;
      categories = [ "Network" "Office" ];
    };
    codex = {
      name = "Codex CLI";
      comment = "Open OpenAI Codex in a terminal";
      exec = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.codex}/bin/codex";
      terminal = false;
      categories = [ "Development" "Utility" ];
    };
  } // lib.optionalAttrs (hostName == "MercDesk") {
    kytyps5 = {
      name = "KytyPS5";
      comment = "Build on first launch, then start the PS5 emulator";
      exec = "${kytyps5Launcher}/bin/kytyps5";
      terminal = false;
      categories = [ "Game" "Emulator" ];
    };
  });

  xdg.mimeApps = lib.mkIf isLinux {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };

  # Keep the project's wallpaper directory linked into the user's home.
  home.file."Pictures/Wallpapers".source = ./Wallpapers;

  # Shared Umbriel configuration for all Linux Home Manager profiles.
  xdg.configFile."umbriel/config.toml" = lib.mkIf isLinux {
    source = (pkgs.formats.toml {}).generate "umbriel-config.toml" {
      general = {
        autostart = [ "noctalia" ];
      };

      output = lib.optionalAttrs (hostName == "MercDesk") {
        "HDMI-A-3".mode = "1920x1080@165";
      };

      layout = {
        mode = "dwindle";
        gap = 8;
      };
      input = {
        keyboard = {
          layout = "us";
        };
        cursor = {
          size = 24;
        };
      };
      keybinds = {
        "Mod+Return" = "spawn:ghostty";
        "Mod+E" = "spawn:nautilus";
        "Mod+B" = "spawn:firefox";
        "Mod+Shift+E" = "spawn:zeditor";
        "Mod+Shift+C" = "spawn:firefox --new-window https://chatgpt.com";
        "Mod+Shift+X" = "spawn:ghostty -e codex";

        "Mod+Space" = "spawn:noctalia msg panel-toggle launcher";
        "Mod+S" = "spawn:noctalia msg panel-toggle control-center";
        "Mod+Comma" = "spawn:noctalia msg settings-toggle";
        "Mod+Shift+Q" = "spawn:noctalia msg panel-toggle session";
        "Mod+Alt+L" = "spawn:noctalia msg session lock";
        "Mod+Shift+S" = "spawn:noctalia msg screenshot-region";
        "Alt+Tab" = "spawn:noctalia msg window-switcher hold";

        "Mod+Q" = "window-close";
        "Mod+F" = "window-toggle-fullscreen";
        "Mod+O" = "overview-toggle";
        "Mod+Left" = "window-focus-left";
        "Mod+Right" = "window-focus-right";
        "Mod+Up" = "window-focus-up";
        "Mod+Down" = "window-focus-down";
        "Mod+Shift+Left" = "window-move-left";
        "Mod+Shift+Right" = "window-move-right";
        "Mod+Shift+Up" = "window-move-up";
        "Mod+Shift+Down" = "window-move-down";
        "Mod+BracketLeft" = "window-consume-left";
        "Mod+BracketRight" = "window-consume-right";
        "Mod+R" = "window-cycle-primary-extent";

        "Mod+1" = "workspace-switch:1";
        "Mod+2" = "workspace-switch:2";
        "Mod+3" = "workspace-switch:3";
        "Mod+4" = "workspace-switch:4";
        "Mod+5" = "workspace-switch:5";
        "Mod+6" = "workspace-switch:6";
        "Mod+7" = "workspace-switch:7";
        "Mod+8" = "workspace-switch:8";
        "Mod+9" = "workspace-switch:9";
        "Mod+Shift+1" = "window-move-to-workspace:1";
        "Mod+Shift+2" = "window-move-to-workspace:2";
        "Mod+Shift+3" = "window-move-to-workspace:3";
        "Mod+Shift+4" = "window-move-to-workspace:4";
        "Mod+Shift+5" = "window-move-to-workspace:5";
        "Mod+Shift+6" = "window-move-to-workspace:6";
        "Mod+Shift+7" = "window-move-to-workspace:7";
        "Mod+Shift+8" = "window-move-to-workspace:8";
        "Mod+Shift+9" = "window-move-to-workspace:9";

        "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
        "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
        "XF86AudioMute" = "spawn:noctalia msg volume-mute";
        "XF86AudioMicMute" = "spawn:noctalia msg mic-mute";
        "XF86MonBrightnessUp" = "spawn:noctalia msg brightness-up";
        "XF86MonBrightnessDown" = "spawn:noctalia msg brightness-down";
        "Mod+Escape" = "session-quit";
      };
    };
  };
}
