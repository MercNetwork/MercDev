{
  # WinBoat runs a Windows VM through Docker (KVM-in-a-container) and
  # gives it seamless RDP-backed integration on the Linux side. That
  # means it needs two things a plain package install won't give it:
  # Docker itself running, and mercury able to talk to both Docker and
  # /dev/kvm without sudo.
  users.mercury.nixos.pc = {pkgs, ...}: {
    virtualisation.docker.enable = true;

    users.users.mercury.extraGroups = ["docker" "kvm"];

    environment.systemPackages = [pkgs.winboat];

    # WinBoat's own current nixpkgs packaging bundles an Electron build
    # that nixpkgs has marked insecure (EOL, no further security
    # patches) — nixpkgs refuses to evaluate any such package at all
    # unless explicitly allow-listed, on any host, regardless of
    # `allowUnfree` (a completely separate mechanism — this is about
    # known-vulnerable packages, not licensing).
    #
    # This is a real, `nix flake check`-caught error, not a
    # hypothetical, and it's pinned to one exact version string on
    # purpose: allow-listing is deliberately per-version, not a
    # standing "ignore all insecure packages" switch, so this line will
    # need bumping (to whatever new version the error names) the next
    # time a `nix flake update` pulls in a newer WinBoat/Electron pair.
    # Check whether WinBoat's own nixpkgs derivation has moved off this
    # Electron version entirely before just re-pinning the number blind.
    nixpkgs.config.permittedInsecurePackages = ["electron-40.10.5"];
  };
}
