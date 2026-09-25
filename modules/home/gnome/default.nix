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

  # ponytail: Kiste läuft als Server (Cockpit :443) — Idle-Suspend nach 15 min legt den Dashboard lahm
  dconf.settings."org/gnome/settings-daemon/plugins/power" = {
    sleep-inactive-ac-type = "nothing";
    sleep-inactive-battery-type = "nothing";
  };
}
