# Build guide: from `configuration.nix` to a dendritic flake

This walks through the Nix concepts behind `TheMercNetwork` (the template
alongside this doc) and how to extend it. Read `SYNOPSIS.md` first for
*why* `mightyiam/infra` looks the way it does; this doc is the hands-on
"how do I actually work with this" companion.

## 0. What changed from your old configuration.nix

Your original setup was one `configuration.nix` that imported one
`hardware-configuration.nix` and one `nvidia.nix`. Everything lived in a
single file per concern, hand-listed in an `imports = [...]`. That's
completely normal NixOS and nothing was wrong with it.

The template replaces the "hand-listed imports" part with **auto-import**
(every `.nix` file under `modules/` is discovered and pulled in for you)
and splits the single file into ~20 small, single-purpose ones. The
*content* — `services.pipewire.enable = true;`, `boot.loader.systemd-boot.enable = true;`,
etc. — is nearly all still there, just relocated. Diff the template
against your original three files if you want to see this directly; very
little was invented, mostly just moved and renamed.

## 1. Nix language pieces you need for this pattern

You don't need to be a Nix expert to work with this template, but these
five ideas cover essentially everything in it:

**Modules are just functions that return `{ options = ...; config = ...; }`.**
A NixOS "module" (and a flake-parts module — same system) is a function
taking an attribute set (`{ config, lib, pkgs, ... }`) and returning
another attribute set. `options` *declares* a setting that doesn't exist
yet (a slot). `config` *provides a value* for a setting — any setting,
whether it was declared in this same file or a completely different
one. Most of the files in `modules/` only ever provide `config`; only a
handful (`nixos/base.nix`, `nixos/pc.nix`, `users.nix`,
`home-manager.nix`, `nixos/configurations.nix`) declare new `options`.

**`imports` is how modules include other modules.** `imports = [ A B ];`
means "also evaluate A and B as part of me." Nesting is unlimited —
a module in an `imports` list can itself have its own `imports`. This is
what makes a `deferredModule` option (see next) work at all: its merged
value is just `{ imports = [ everyone's contribution ]; }`.

**`lib.types.deferredModule` is "a bucket many files can add to."**
`modules/nixos/base.nix` declares one:
```nix
options.nixos.modules.base = lib.mkOption { type = lib.types.deferredModule; default = {}; };
```
Any file, anywhere, can now write `config.nixos.modules.base = { ...some NixOS config... };`
and it gets folded in. This is the whole trick behind splitting one
`configuration.nix` into `boot.nix`, `audio.nix`, `networking.nix`,
etc. — each contributes independently to the same bucket, and a host
imports the bucket once to get everyone's contribution.

**`lib.mkDefault` / `lib.mkIf` / `lib.mkForce` resolve conflicts, so two
files can mention the same setting without erroring.** If two plain
assignments try to set `time.timeZone` to different values, Nix errors
("conflicting definitions"). `lib.mkDefault "America/Chicago"` says "use
this *unless* something more specific overrides it" — which is exactly
how `modules/locale.nix` sets a fallback timezone that `merclaptop.nix`
then overrides with a plain (higher-priority) assignment, with no error.
`lib.mkForce` is the strongest override; `lib.mkIf cond value` only
applies `value` when `cond` is true.

**Attribute-name interpolation lets a variable become part of an option
path.** `home-manager.users.${username} = ...;` — the `${...}` splices a
runtime string into what would otherwise be a fixed name. This is how
`users.nix` can define behavior for "whatever the username is" once,
instead of once per user.

If those five ideas make sense, every file in this template should read
comfortably.

## 2. How `flake.nix` finds your config

```nix
imports = [((import import-tree) ./modules)];
```

`import import-tree` loads a small function; calling it with `./modules`
walks that directory recursively and returns every `.nix` file found,
**except** ones whose name (or an ancestor directory's name) starts with
`_`. Those get returned as a flat list, which flake-parts then imports
like any other `imports` list.

Practical consequences:

- **Adding a file is enough.** Create `modules/mercury/games.nix` with
  some `home.gui = {...}` content, save it, and it's part of the
  evaluation next time you run any `nix` command — no registration step.
- **Moving a file is safe.** Reorganize `modules/mercury/*` into
  subfolders freely; nothing references files by path except the
  underscore-prefixed exceptions (see next point), which are referenced
  explicitly and will need their `import` path updated if you move
  *them*.
- **Prefix a file with `_` to hide it from auto-import.** This template
  does this for each host's hardware scan —
  `modules/computers/_merclaptop-hardware-configuration.nix`,
  `_mercdesktop-hardware-configuration.nix`, and
  `_mercserver-hardware-configuration.nix` — plain NixOS modules (not
  shaped like flake-parts modules: no `options`/`config` split, just raw
  `fileSystems`/`boot` attrs) that would error if
  auto-imported as-is. Each is `imports`-ed by explicit relative path
  from its own host file instead (`merclaptop.nix`, `mercdesktop.nix`,
  `mercserver.nix`).
- **Untracked files are invisible to Nix, not just to git.** Flakes only
  see files that are tracked by git (`git add`). If you create a new
  module and `nix flake check` doesn't seem to notice it, `git add` it
  first.

## 3. Anatomy of one host: `merclaptop.nix`

```nix
{config, ...}: {
  nixos.configurations.merclaptop.module = {
    imports = [
      ./_merclaptop-hardware-configuration.nix
      config.nixos.modules.pc
      config.users.mercury.nixos.pc
    ];
    system.stateVersion = "26.05";
    time.timeZone = "America/Chicago";
  };
}
```

Three `imports` entries, each doing a different job:

1. **The hardware scan** — machine-specific facts (disk UUIDs, kernel
   modules) that only apply to this one laptop.
2. **`config.nixos.modules.pc`** — everything *every* GUI machine you
   own should get: audio, networking, boot defaults, nix settings,
   home-manager wiring. Defined once, reused by every host you ever add.
3. **`config.users.mercury.nixos.pc`** — mercury's account, COSMIC, and
   home-manager config. If mercury ever logs into a second machine, this one line is all that machine needs to get the exact same account
   and desktop.

Then two host-specific overrides that don't belong in any shared bucket:
`system.stateVersion` (set once at first install, per NixOS convention —
see the comment in `modules/nix-settings.nix` for why it isn't a shared
default) and `time.timeZone` (shown here as a plain override of the
`mkDefault` in `modules/locale.nix`, in case mercury moves time zones
without needing to touch a shared file).

## 4. Adding a second host

This template already has three real hosts (`merclaptop`, `mercdesktop`,
`mercserver`) — `modules/computers/mercdesktop.nix` is a good live
example to read alongside this section. Here's the walkthrough that
produced it, generalized to a fourth host, say a tablet, `merctablet`,
also running COSMIC:

1. Run `nixos-generate-config --show-hardware-config` on the new machine,
   save the output as
   `modules/computers/_merctablet-hardware-configuration.nix`.
2. Create `modules/computers/merctablet.nix`:
   ```nix
   {config, ...}: {
     nixos.configurations.merctablet.module = {
       imports = [
         ./_merctablet-hardware-configuration.nix
         config.nixos.modules.pc
         config.users.mercury.nixos.pc
       ];
       system.stateVersion = "26.05";
     };
   }
   ```
3. That's it — `nixosConfigurations.merctablet` now exists. mercury's
   account, COSMIC, and every `pc`-bucket module are already wired
   in, because they live in shared buckets, not in `merclaptop.nix`.
4. If the tablet has a discrete GPU, add the matching named module to
   its `imports` too — see `modules/hardware/nvidia.nix` (used by
   `merclaptop`) or `modules/hardware/intel-arc.nix` (used by
   `mercdesktop`) as two real examples of the same opt-in pattern.
5. A *headless* host (no display) is the one place this shortcut
   doesn't apply as-is: skip `config.nixos.modules.pc` and
   `config.users.mercury.nixos.pc` in favor of `.base`, and see the
   gotcha about `boot.loader`/`i18n.defaultLocale` in section 7 — or
   just read `modules/computers/mercserver.nix`, which is exactly that
   case.

## 5. Adding a second user

Say mercury's partner, Alex, gets an account on the laptop too:

1. `mkdir modules/alex`
2. `modules/alex/identity.nix`:
   ```nix
   { users.alex = { fullName = "Alex Whoever"; initialPassword = "changeme123"; }; }
   ```
3. `modules/alex/desktop-environment.nix` — reuse COSMIC, or give Alex a
   different one entirely (this is exactly how mightyiam/infra gives
   `bow` COSMIC while `mightyiam` gets Hyprland — nothing stops two
   users on the same repo from having completely different desktops):
   ```nix
   { users.alex.nixos.pc.services.desktopManager.gnome.enable = true; }
   ```
4. Add `config.users.alex.nixos.pc` to `merclaptop.nix`'s `imports` list
   (or make a shared "everyone on this laptop" list if the household
   grows — that's just another `deferredModule` bucket, same pattern).

## 6. Day-to-day commands

```sh
# Evaluate everything without building — catches typos fast.
nix flake check

# See what a build would change without applying it. Swap in
# mercdesktop or mercserver for the other two hosts.
sudo nixos-rebuild dry-build --flake .#merclaptop

# Apply for this boot only — reboot reverts.
sudo nixos-rebuild test --flake .#merclaptop

# Apply and make it the default boot entry.
sudo nixos-rebuild switch --flake .#merclaptop

# Update all inputs (nixpkgs, home-manager, flake-parts, import-tree,
# nixvim, ...) to their latest commits, recording the result in
# flake.lock. Run this once after cloning, too — a fresh checkout has
# no flake.lock at all until this runs once.
nix flake update

# Update just one input.
nix flake lock --update-input nixpkgs
```

This repo lives at `/mercury` rather than the conventional `/etc/nixos`,
so either run these commands from inside `/mercury`, or point at it
explicitly: `sudo nixos-rebuild switch --flake /mercury#merclaptop`.

## 7. Gotchas specific to this pattern

- **Everything must be `git add`ed.** Flakes hash the git tree; an
  untracked new file is invisible to Nix even though it's right there on
  disk. `git add -A` before every `nix flake check` while iterating is a
  good habit.
- **The pipe operator (`|>`) needs a recent Nix and the experimental
  flag.** `flake.nix`'s `nixConfig.extra-experimental-features = ["pipe-operators"];`
  handles this for anyone using this flake, but if you ever copy a
  snippet using `|>` into a *different*, non-flake context (a `nix repl`,
  a standalone script), it won't work there unless you pass
  `--extra-experimental-features pipe-operators` yourself.
- **`deferredModule` values are lazy.** You can reference
  `config.users.mercury.nixos.pc` from a file that's evaluated before
  `modules/mercury/*.nix` ever runs, in any order, and it works — Nix
  doesn't actually evaluate a `deferredModule`'s contents until
  something `imports` it for real. Don't worry about "file ordering";
  there isn't any in this pattern.
- **Two plain (non-`mkDefault`) definitions of the same option conflict.**
  If you copy a setting into both a shared bucket file and a host file
  by mistake, expect a "conflicting definition values" error. The fix is
  almost always: make the shared one `lib.mkDefault`, leave the specific
  one plain.
- **`system.stateVersion` per host, never as a shared default.** It's
  meant to reflect "whatever NixOS release was current the first time
  this specific machine was installed," so home-manager and NixOS can
  keep old on-disk formats compatible across upgrades. Copying it as a
  `mkDefault` in a shared bucket (tempting, since it looks like "just
  another setting") defeats that purpose for every future host.
- **DMS is `programs.dms-shell`, not `programs.dank-material-shell`.**
  Historical note, not current: this repo briefly ran niri +
  DankMaterialShell instead of COSMIC, and DMS's Nix packaging was
  young enough at the time to produce three separate `nix flake check`
  failures before working correctly — a fabricated option, a mismatched
  module family, and a plugin schema mismatch. It's back to COSMIC now
  (see `modules/mercury/desktop-environment.nix`), but if you're ever
  tempted to try niri + DMS again yourself: `programs.dms-shell` is the
  correct, native-nixpkgs module family (as of nixpkgs 26.05), not
  `programs.dank-material-shell` (a different option tree, from DMS's
  own flake) — the two aren't interchangeable, and mixing them is
  exactly what caused the second of those three failures.
- **`mercserver` doesn't import `nixos.modules.pc`.** It's headless, so
  it skips COSMIC, audio, and networkmanager — but that also means it
  doesn't inherit `boot.loader.*` or `i18n.defaultLocale` from
  `boot.nix`/`locale.nix`, which are scoped to `pc` only. `mercserver.nix`
  sets those directly instead. Keep this in mind if you add a fourth
  headless host: it needs the same, not just a copy-paste of
  `mercdesktop.nix`.

## 8. Where to go next (in `mightyiam/infra`, roughly in order of payoff)

1. **`modules/repository/formatting.nix` (treefmt) + a pre-commit hook**
   — cheap, immediately useful, keeps every file consistently styled as
   the repo grows.
2. **Split `modules/mercury/home.nix` the same way `mightyiam/infra`
   splits its per-user directory** — one file per app/concern
   (`shell.nix`, `terminal.nix`, `git.nix`, `browsers.nix`, ...) as it
   grows past "a few packages." The dendritic pattern's entire value
   proposition shows up once a single-user config exceeds ~100 lines.
3. **`nixos-facter`**, if you end up with more than two or three
   machines — replacing hand-copied `hardware-configuration.nix` files
   with detected reports removes an entire category of "did I copy the
   right hardware config" mistakes.
4. **Stylix**, for theming home-manager + system consistently from one
   color scheme definition, the way `modules/bow/style/*.nix` does for
   the COSMIC user in the original repo.
5. **`git-hooks.nix` + `nixConfig.abort-on-warn`**, once the config feels
   stable enough that catching regressions automatically is worth more
   than the friction of stricter checks.

None of these are prerequisites for a working, COSMIC-based,
single-laptop setup — they're the path from "this template" to
"something as mature as `mightyiam/infra`," at whatever pace you want to
walk it.
