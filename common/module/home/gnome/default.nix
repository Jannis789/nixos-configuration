{ config, lib, pkgs, ... }:
{
  # GNOME Gesamtmodul — sammelt alle GNOME-Submodule.
  # Neues dazu: Datei in gnome/ anlegen + hier importieren.
  imports = [
    ./dock.nix
  ];
}
