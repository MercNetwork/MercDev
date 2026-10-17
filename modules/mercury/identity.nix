{
  users.mercury = {
    username = "mercury";
    fullName = "Hunter Welch";

    # Only takes effect on first boot / when the account has no password
    # hash yet. Change it right after first login with `passwd`, or
    # better, manage it declaratively later with sops-nix or
    # `users.users.mercury.hashedPasswordFile`.
    initialPassword = "Chloe";
  };
}
