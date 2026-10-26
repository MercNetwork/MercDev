# Wallpapers

Drop wallpaper images here. This directory is symlinked to
`~/Pictures/Wallpapers` for mercury on every GUI host (see
`modules/mercury/wallpapers.nix`) via a live, out-of-store symlink —
so anything added here shows up immediately, no `nixos-rebuild` needed.

This is plain data, not Nix — it's outside `modules/`, so `import-tree`
never touches it. Keep this placeholder or delete it once real
wallpapers are added.
