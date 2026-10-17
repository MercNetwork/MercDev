{
  description = "TheMercNetwork — mercury's Nix-powered infrastructure (dendritic / flake-parts pattern, COSMIC edition)";

  # Nothing below is arranged into "one big config" the way a classic
  # configuration.nix is. Every *.nix file under ./modules is its own
  # flake-parts module and gets auto-imported by import-tree (see the
  # `imports` line below). Files may declare *options* (new settings that
  # don't exist yet) and/or *config* (values for options, from anywhere).
  # This is the "dendritic pattern" — see docs/SYNOPSIS.md and
  # docs/BUILD_GUIDE.md for a full explanation.

  # `|>` below is the "pipe operator": `x |> f |> g` means `g (f x)`.
  # It reads left-to-right instead of nesting parens inside-out, which
  # is why mightyiam/infra (and this template) leans on it heavily.
  # It's an experimental Nix language feature, so it must be switched on
  # here. Requires a reasonably recent Nix (2.24+).
  nixConfig.extra-experimental-features = ["pipe-operators"];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    # Auto-discovers and imports every .nix file under a directory as a
    # flake-parts module, recursively. Files/dirs starting with "_" are
    # skipped, which is how we hide plain (non-flake-parts) files, like
    # raw hardware-scan files, from being treated as modules.
    import-tree = {
      url = "github:vic/import-tree";
      flake = false;
    };

    # nixvim: a Neovim configuration framework where the editor's whole
    # config is itself a NixOS/home-manager module, instead of Lua files
    # this repo would otherwise have to hand-manage. Unrelated to the
    # desktop environment — works the same regardless of which one is
    # in use.
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      imports = [((import import-tree) ./modules)];
    };
}
