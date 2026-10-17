# Synopsis: `mightyiam/infra`

Source: https://github.com/mightyiam/infra (MIT, ~1,674 commits, Nix 100%)

This is Shahar "Dawn" Or's (mightyiam's) personal NixOS + home-manager
configuration for several machines and two users. It is not a "starter
template" in spirit — it's a mature, opinionated, several-years-old system —
but it is *extremely* instructive because it's also the birthplace of a
named technique, **the dendritic pattern**, that this document exists to
explain.

---

## 1. The shape of the repo

```
flake.nix        <- auto-generated, ~80 lines, just inputs + nixConfig
outputs.nix       <- 6 lines: hands everything to flake-parts
modules/          <- ~200 files, EVERYTHING lives here
  <flat and nested, organized by topic, not by "type of Nix thing">
```

That's it. There is no `hosts/`, no `home/`, no `nixos/` split at the top
level the way most public NixOS configs are organized. Nearly the entire
repository is one `modules/` directory containing ~200 `.nix` files,
organized by *subject matter* — `audio/`, `gaming/`, `hardware/`,
`networking/`, two per-user directories (`mightyiam/`, `bow/`) — rather
than by *what kind of flake output they produce*. A file about Hyprland
keybindings and a file about the Bitwarden CLI live nowhere near each
other technically, but that's fine, because nothing about how the repo
is *evaluated* depends on directory structure at all.

That last sentence is the entire point of the dendritic pattern, and
it's worth sitting with.

---

## 2. `outputs.nix`: the whole entry point

```nix
inputs: let
  lib = import "${inputs.nixpkgs}/lib";
in
  inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    debug = true;
    imports = [((import inputs.import-tree).filterNot (lib.hasSuffix ".pkg.nix") ./modules)];
    _module.args.rootPath = ./.;
  }
```

Read this literally: the *only* thing this repository's Nix evaluation
does by hand is call `flake-parts.lib.mkFlake`, and its only `imports`
entry is the *entire `./modules` directory*, filtered to exclude files
ending in `.pkg.nix` (those are picked up separately, by a package
discovery module, not as flake-parts modules).

`import-tree` (https://github.com/vic/import-tree) is a small library
whose entire job is: walk a directory recursively, find every `.nix`
file, skip any file or directory whose name starts with `_`, and return
a list of paths — which flake-parts then imports as **flake-parts
modules**. No file anywhere in the tree is ever referred to by a literal
`import ./some/path.nix` — everything gets pulled in automatically.

### Why this matters

In an ordinary flake-parts (or even plain NixOS) project, someone adds a
new file and then has to remember to also add `./new-file.nix` to some
central `imports` list — usually in `flake.nix` or a `default.nix`. That
central list becomes a second source of truth that has to be kept in
sync with the filesystem, and it actively discourages splitting things
into small files, because every split means another edit to the list.

With auto-import, moving, renaming, splitting, or merging files is
*purely a filesystem operation*. There is nothing else to update. This
is what allows `mightyiam/infra` to have ~200 tiny, single-purpose files
instead of a handful of 500-line ones — the cost of splitting a file in
two dropped to zero.

---

## 3. flake-parts, and what a "module" means here

[flake-parts](https://github.com/hercules-ci/flake-parts) is a small
framework that lets you build a flake's `outputs` the same way NixOS
builds a system: as a set of **modules**, each of which can declare new
**options** and/or provide **config** (values) for options — including
options declared in a totally different file. The final flake outputs
(`packages`, `devShells`, `nixosConfigurations`, `checks`, ...) are just
the values of certain conventional options after every module has been
merged.

This is the exact same module system NixOS itself is built on
(`lib.evalModules`) — flake-parts just points it at "the flake" instead
of "a running system." That's why the vocabulary transfers directly:
`options`, `config`, `imports`, `mkOption`, `mkIf`, `mkDefault`,
`mkMerge`, submodules — all of it is the ordinary NixOS module system,
reused.

Concretely, a flake-parts module file usually looks like:

```nix
{ config, lib, pkgs, inputs, ... }: {
  options.some.new.option = lib.mkOption { ... };
  config.some.existing.option = ...;
}
```

or, when a file only *sets* values and declares nothing new (the common
case for a "content" file, as opposed to an "infrastructure" file):

```nix
{
  perSystem.something = ...;      # this is already `config`, implicitly
}
```

flake-parts also injects useful things as module arguments for free:
`perSystem` (a per-`system` sub-evaluation, so you don't hand-loop over
`x86_64-linux`/`aarch64-linux`/etc.), `withSystem`, and any custom
`_module.args` another module chose to inject (this repo injects
`rootPath`, `mkModuleOption`, `evalModulesModule`, `removeStorePathPrefix`,
`homeManager`, and more — see below).

---

## 4. Custom options: how NixOS *systems* get built from scattered files

flake-parts gives you `packages`, `devShells`, `checks`, `apps`, and a
few other conventional options out of the box, but it does **not** know
what a "NixOS configuration" or a "user" is — those are concepts
`mightyiam/infra` invents itself, as custom options, in
`modules/nixos.nix` and `modules/users.nix`.

### 4.1 `nixos.configurations.<name>`

```nix
options.nixos.configurations = lib.mkOption {
  type = lib.types.lazyAttrsOf (
    lib.types.submodule ({name, ...}: {
      imports = [evalModulesModule];
      options.name = lib.mkOption { readOnly = true; default = name; };
      config = {
        fn = import "${inputs.nixpkgs}/nixos/lib/eval-config.nix";
        args = {system = null;};
      };
    })
  );
};
```

This declares a *registry*: an attribute set where each key (e.g.
`astraeus`, `dobby`, `termitomyces`) is a "computer," and each computer
is itself a little module system (a `submodule`) with its own
`options`/`config`. The registry entry doesn't build a NixOS system
directly — it collects a `module` (arbitrary NixOS config, via
`imports`) and, through the shared `evalModulesModule` helper
(`modules/eval-modules.nix`), calls the *real* NixOS evaluator
(`eval-config.nix`, the same function `nixpkgs.lib.nixosSystem` wraps)
lazily, producing a `configuration` attribute.

Elsewhere:

```nix
flake.nixosConfigurations =
  config.nixos.configurations |> lib.mapAttrsToList (name: {configuration, ...}: configuration);
```

turns the whole registry into the ordinary `nixosConfigurations` flake
output. Every host file (`modules/computers/astraeus.nix`, etc.) simply
does:

```nix
nixos.configurations.astraeus.module = { imports = [...]; ... };
```

— it contributes to the registry from wherever it lives; it never calls
`nixosSystem` itself.

**Why the custom evaluator instead of plain `nixosSystem`?** Because
`nixosSystem` wants a `system` string (`"x86_64-linux"`, etc.) up front,
and this repo determines each host's `system` from *hardware-detected
facts* (see §7, `nixos-facter`) rather than hand-typing it — so the
registry defers evaluation until that fact is known, instead of
requiring it as an input.

### 4.2 `users.<name>`

`modules/users.nix` declares an almost identical registry, but for
*people* instead of *machines*: `users.mightyiam`, `users.bow`. Each
user gets four **buckets** — `nixos.base`, `nixos.pc`, `home.base`,
`home.gui` — that any file, anywhere, can add to:

```nix
users.mightyiam.home.gui = { pkgs, ... }: { home.packages = [ pkgs.neofetch ]; };
```

`pc` always imports `base`, and `home.gui` always imports `home.base`,
so a host only ever has to import one thing
(`config.users.mightyiam.nixos.pc`) to get everything anyone,
anywhere in the repository, contributed to that user.

This bucket idea — a `deferredModule`-typed option that many files add
to — is the second half of the dendritic pattern (§3 was "don't hand-list
files"; this is "don't hand-list *contributions to a thing* either").
It's implemented via a small helper, `mkModuleOption` (`modules/lib.nix`):

```nix
mkModuleOption = { key, static ? {}, ... }:
  lib.mkOption {
    type = lib.types.deferredModuleWith { staticModules = [ static ]; };
    apply = module: { inherit key; imports = [ module ]; };
    default = {};
  };
```

`lib.types.deferredModule` is a NixOS module-system type whose values
are themselves *unevaluated modules* — attribute sets, functions, or
paths that only get evaluated once they're `imports`-ed somewhere else.
Its `merge` behavior collects every definition into a list and wraps it
as `{ imports = [...] }`. That's *exactly* "let many files each hand a
piece of config to one bucket, then evaluate the whole bucket once,
somewhere else, at the very end" — no explicit `lib.mkMerge` needed,
because the type itself knows how to merge.

---

## 5. `home-manager.nix`: wiring, not policy

```nix
_module.args.homeManager = import "${inputs.home-manager}/lib" {inherit lib;};

nixos.modules.base = {pkgs, ...}: {
  home-manager.sharedModules = [
    ({osConfig, ...}: {
      home.stateVersion = osConfig.system.stateVersion;
      stylix.overlays.enable = false;
    })
  ];
  home-manager.backupCommand = lib.getExe' pkgs.trash-cli "trash-put";
};
```

Two things worth noting: (1) `home.stateVersion` is *derived* from
`system.stateVersion`, per-host, via `osConfig` — so it's never typed
twice and never drifts; (2) `backupCommand` uses `trash-cli` instead of
just renaming conflicting files to `.bak`, so a `home-manager switch`
that would overwrite something sends the old version to the trash
instead of silently clobbering it.

---

## 6. Two users, two entirely different desktops, one repository

This is one of the more striking things once you notice it:
`modules/mightyiam/window-manager/core.nix` configures **Hyprland**
(with the `hy3` tiling plugin, vim-style `hjkl` bindings) for the
`mightyiam` user, while `modules/bow/desktop-environment.nix` enables
**COSMIC** —

```nix
users.bow = {
  wayland.sessions = pkgs: [pkgs.cosmic-session];
  nixos.pc.services = {
    system76-scheduler.enable = true;
    desktopManager.cosmic.enable = true;
  };
  home.gui = {pkgs, ...}: {
    xdg.mimeApps.defaultApplicationPackages = [pkgs.cosmic-edit pkgs.loupe];
  };
};
```

— for the `bow` user, on a different machine entirely. Nothing about the
repository's *structure* privileges one over the other; they're simply
two independent contributors to the same `users.<name>` and
`nixos.configurations.<name>` registries. This is the payoff of the
pattern: radically different setups coexist without needing separate
top-level trees, separate flakes, or copy-pasted boilerplate — the
*registries* are shared infrastructure, the *content* is per-user/host.

(This is also exactly why this template borrows the registries
wholesale but writes fresh `mercury/*.nix` content for COSMIC, rather
than trying to reuse `mightyiam`'s Hyprland-flavored files.)

---

## 7. Hardware: `nixos-facter` instead of `nixos-generate-config`

Rather than checked-in `hardware-configuration.nix` files,
`mightyiam/infra` uses [`nixos-facter`](https://github.com/nix-community/nixos-facter),
a hardware-detection tool whose output is a JSON *report* rather than a
`.nix` file:

```nix
nixos.configurations.astraeus.facter.reportPath = ./astraeus.facter.json;
```

`modules/hardware/facter.nix` reads that JSON at eval time
(`lib.readFile` + `lib.fromJSON`) and feeds it to
`hardware.facter.report`, a NixOS module (from the `nixos-facter-modules`
project, referenced indirectly) that turns hardware *facts* — PCI IDs,
detected kernel modules, the `system` string itself — into the same
kind of config `hardware-configuration.nix` would otherwise hand-write.
`modules/repository/systems.nix` even derives flake-parts's `systems`
list from these reports, rather than hardcoding
`["x86_64-linux"]` — the set of systems the flake supports is itself a
*fact*, derived from real hardware, not a guess.

This template does **not** use facter — mercury's machine already has a
conventional `hardware-configuration.nix` from `nixos-generate-config`,
and introducing facter is an orthogonal upgrade you can make later (see
`BUILD_GUIDE.md` §7). It's included here because it's a distinctive,
non-obvious technique worth knowing this codebase relies on.

Disk layout is handled with a small `boot.partlabels` abstraction
(`modules/boot.nix`) that turns a list of GPT partition *labels* (not
device paths, which aren't stable) into `fileSystems` and
`loader.grub.mirroredBoots` entries — this repo prefers GRUB with
mirrored ESPs across two physical disks (`boot0`/`boot1`) for
redundancy, plus ZFS (`modules/storage/zfs.nix`) as the root filesystem
on most hosts.

---

## 8. Nix-language features this repo leans on

| Feature | Where | What it does |
|---|---|---|
| `\|>` pipe operator | everywhere | `x \|> f \|> g` = `g (f x)`. An experimental Nix 2.24+ feature, enabled via `nixConfig.extra-experimental-features = ["pipe-operators"];`. Reads left-to-right instead of nesting. |
| `lib.types.deferredModule` | `mkModuleOption`, every bucket option | A module-system type whose *values* are themselves unevaluated modules, merged by concatenating them into an `imports` list. This is the mechanism behind "many files, one bucket." |
| `lib.types.lazyAttrsOf (lib.types.submodule ...)` | `nixos.configurations`, `users` | A registry: an attrset of named, independently-evaluated sub-configs (each with its own `options`/`config`). |
| `mkOption { apply = ...; }` | `mkModuleOption` | Post-processes a merged option value before anything reads it — here, wrapping a raw module in `{ key; imports = [module]; }`. |
| `_module.args` | `modules/lib.nix`, `modules/home-manager.nix`, `outputs.nix` | Injects extra arguments (like `mkModuleOption`, `homeManager`, `rootPath`) into *every* module's function signature, project-wide, without an explicit import anywhere. |
| `mkIf` / `mkDefault` / `mkMerge` / `mkForce` | throughout | Standard NixOS module-system priority/conditionality primitives — a later, more specific definition can override an earlier, more general default without an explicit "if" branch. |
| `@`-pattern argument binding | `nameArgs @ {name, ...}: ...` | Captures both the whole argument set (`nameArgs`) and a destructured field (`name`) at once — used constantly to reach `nameArgs.config.someOtherOption` from inside a submodule that only destructured `{name, ...}`. |
| String interpolation into attribute names | `home-manager.users.${name} = ...` | Dynamic attribute names built from a variable — required any time a registry key (a hostname, a username) needs to become part of a real NixOS/home-manager option path. |
| `readOnly` options | `configuration`, `name` | Marks a computed value as non-overridable — it can be *read* from anywhere but never *set*, catching accidental attempts to redefine something that should only ever be derived. |
| `lib.readFile` + `lib.fromJSON` | `modules/hardware/facter.nix` | Pulls external, non-Nix data (a JSON hardware report) into the module system as ordinary values, at evaluation time. |
| Files prefixed with `_` | `modules/computers/_teeveera.nix` | The one manual escape hatch from auto-import: a file that import-tree deliberately skips, referenced by an explicit relative path from wherever it's actually needed (e.g. a raw NixOS module that isn't shaped like a flake-parts module). |
| `specialisation` | `dobby.nix`, `ganoderma.nix` | A NixOS feature (not specific to this repo) for building an *alternate boot entry* that only changes a few settings (e.g. swap to the proprietary Nvidia driver) without needing a second, separately-built host. |

---

## 9. Repository tooling (the "meta" layer)

A meaningful fraction of `modules/repository/*.nix` isn't about any
machine at all — it's about the repository itself:

- **Generated files** (`modules/repository/files.nix` + the `files`
  input): `.gitignore`, `LICENSE`, and `README.md` are *built*, not
  hand-maintained. Other modules contribute snippets — e.g.
  `modules/repository/auto-import.nix` has
  `perSystem.text.readme.parts.auto-import = "## Automatic import\n...";`
  — which get assembled into the final README. The README you read on
  GitHub is quite literally rendered from the same dendritic pieces as
  the configuration.
- **`git-hooks.nix` / `git.ignore`**: pre-commit-style hooks and a
  `git.ignore` *option* (rather than a hand-written `.gitignore`) that
  other files add patterns to (`git.ignore = ["*.qcow2"];` from the VM
  variant).
- **`treefmt-nix`**: one formatter invocation covers every language in
  the repo (Nix, Lua, JSON, Markdown, ...), each file just declares
  which formatter it wants for its language.
- **`make-shell`**: builds the repo's own `devShells.default`.
- **`all-check-store-paths`**: a package that builds a TOML file mapping
  every flake check to the resulting `/nix/store` path — used to answer
  "did this refactor actually change any built output, or just move
  code around?" by diffing that TOML across commits.
- **`nixConfig.abort-on-warn = true`** (repo-wide, in the generated
  `flake.nix`): turns Nix evaluation warnings into hard errors, so
  deprecated-option warnings can't silently accumulate.
- **`prohibit-import-from-derivation.nix`** /
  **`prohibit-warnings.nix`**: enforce the above as CI-checkable
  invariants, not just personal discipline.

None of this is necessary to use the dendritic pattern — it's the
"advanced/optional" layer once the basic pattern is in place, and it's
called out explicitly in `BUILD_GUIDE.md` as things to add later, not
day one.

---

## 10. What this template deliberately does *not* copy

- **`nixos-facter`** — kept the conventional `hardware-configuration.nix`
  you already have.
- **Generated `flake.nix`/README/LICENSE via the `files` module** —
  hand-written instead, so there's one less moving part while you're
  learning the pattern.
- **`mkModuleOption`'s `key` field** — mightyiam's version tags every
  bucket with a `key` string (probably for tooling elsewhere in a
  private branch, or debugging which bucket a given config came from);
  the template's buckets are plain `deferredModule` options without it,
  since it isn't load-bearing for the pattern itself.
- **Hyprland, nushell, the `armilaria` Neovim distribution, gaming,
  ZFS, `nixos-facter`, `specialisation`-based Nvidia toggling** — all
  real, all worth studying later, none of them required to get COSMIC
  running on one laptop.

Everything in that list is a good "next thing to add" once the basic
skeleton in this template feels comfortable — see `BUILD_GUIDE.md`.
