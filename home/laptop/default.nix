# Same home-manager config as jannis (same user).
# Both hosts are NixOS, same homedir structure.
{ ... }: {
  imports = [ ../jannis/default.nix ];
}
