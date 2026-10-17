{
  # Symlinks ~/Pictures/Wallpapers -> /mercury/wallpapers (this repo's
  # canonical host path — see README.md). Deliberately a *live* symlink
  # via mkOutOfStoreSymlink rather than a plain `home.file.source`
  # (which would copy into the Nix store): drop a new image into
  # /mercury/wallpapers and it shows up immediately, with no rebuild.
  #
  # The tradeoff of that: wallpapers themselves aren't reproducible from
  # this flake alone the way everything else here is — they're just
  # files living alongside it in git (or gitignored, your call).
  users.mercury.home.gui = {config, ...}: {
    home.file."Pictures/Wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink "/mercury/wallpapers";
  };
}
