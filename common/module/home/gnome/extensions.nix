{ config, lib, pkgs, ... }:
{
  # GNOME Extensions: installieren + aktivieren
  # (aus rewrite/10_gnome_extensions.md — 7 Extensions)
  home.packages = with pkgs.gnomeExtensions; [
    user-themes
    color-picker
    blur-my-shell
    caffeine
    astra-monitor
    dash-to-dock
    tiling-shell
  ];

  dconf.settings."org/gnome/shell" = {
    enabled-extensions = [
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "color-picker@tuberry"
      "blur-my-shell@aunetx"
      "caffeine@patapon.info"
      "monitor@astraext.github.io"
      "dash-to-dock@micxgx.gmail.com"
      "tilingshell@ferrarodomenico.com"
    ];
  };
}
