{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./dock.nix
    ./extensions.nix
  ];
}
