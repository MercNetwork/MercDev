{ pkgs, ... }:
{
  users.users.mercury = {
    isNormalUser = true;
    description = "Hunter Welch";
    extraGroups = [ "networkmanager" "wheel" "video" "render" "adbusers" ];
    shell = pkgs.zsh;
    # Kept at the user's request; replace before deploying to any machine.
    initialPassword = "chloe";
  };
  programs.zsh.enable = true;
}
