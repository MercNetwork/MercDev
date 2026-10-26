{ ... }:
{
  # Prepared for Apple Silicon, but the flake output is intentionally disabled
  # until the device arrives and the configuration can be tested.
  system.stateVersion = 6;
  nix.enable = true;
  programs.zsh.enable = true;
  homebrew = {
    enable = true;
    casks = [ "chatgpt" "discord" "firefox" "tailscale-app" ];
  };
}
