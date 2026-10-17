{inputs, ...}: {
  # nixvim: Neovim configured as a Nix module instead of hand-written
  # Lua — the same "config as data, not files" idea as everything else
  # in this repo, just applied to an editor instead of a desktop.
  users.mercury.home.gui = {
    # `homeManagerModules` (what this repo originally used) was renamed
    # upstream to `homeModules` — confirmed by `nix flake check` itself
    # via an evaluation warning, not by docs. Same "trust the tool over
    # what a doc/example said" lesson as Chapter 26 of the book.
    imports = [inputs.nixvim.homeModules.nixvim];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # nixvim's own `nixpkgs` input is pinned to a specific commit;
      # `flake.nix` overrides that via `inputs.nixpkgs.follows` (so this
      # repo only ever evaluates one nixpkgs, same reasoning as
      # everywhere else `follows` shows up — see Chapter 6/15 of the
      # book). Left alone, nixvim then warns on every rebuild that its
      # expected nixpkgs commit doesn't match the one actually in use,
      # because by default it builds its *own* separate pkgs instance
      # rather than reusing home-manager's. `useGlobalPackages = true;`
      # tells it to skip that and just reuse the ambient `pkgs` this
      # repo already configured — eliminating the second evaluation
      # (and the warning) rather than just suppressing the message.
      #
      # (`nixpkgs.source` — a path, for pointing nixvim's *own* instance
      # at a specific nixpkgs checkout — was tried here first, based on
      # the warning's own suggested fix text. It's a real option, but
      # the wrong one for what's actually wanted here, and `nix flake
      # check` correctly rejected the plain string `"pkgs"` this file
      # passed it, since the option needs an absolute path, not a
      # string. `useGlobalPackages` is the option that actually matches
      # the intent — confirmed against nixvim's own current docs.)
      nixpkgs.useGlobalPackages = true;

      opts = {
        number = true;
        relativenumber = true;
      };

      # LSP servers for the four languages actually in use here, wired
      # into Neovim's built-in LSP client via nvim-lspconfig.
      #
      # Only `plugins.lsp.enable` is needed to pull nvim-lspconfig in —
      # it does that itself. A separate, additional
      # `plugins.lspconfig.enable = true;` was here originally (based on
      # a docs line describing lspconfig as a companion to install
      # alongside plugins.lsp) but `nix flake check` flagged it as
      # configuring the exact same underlying plugin twice; removed.
      plugins.lsp = {
        enable = true;
        servers = {
          nixd.enable = true; # Nix

          rust_analyzer = {
            enable = true; # Rust
            # rust_analyzer needs cargo/rustc on PATH to do anything
            # useful; without these two, `nix flake check` warns on
            # every rebuild rather than actually installing them.
            # Explicit `true` here means nixvim provides both itself
            # (from nixpkgs, same as everything else in this repo) —
            # no separate Rust toolchain module needed elsewhere.
            installCargo = true;
            installRustc = true;
          };

          pyright.enable = true; # Python
          kotlin_language_server.enable = true; # Kotlin
        };
      };
    };
  };
}
