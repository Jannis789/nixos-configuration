{
  lib,
  writeShellApplication,
  python3,
  glib,
  coreutils,
}:

# Klimmzug für "adaptive Auflösung" bei Sunshine auf GNOME/Wayland:
# Sunshines global_prep_cmd ruft dieses Skript beim Stream-Start mit der
# Client-Auflösung in der Umgebung auf und stellt den primären Monitor per
# org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig auf den passenden Modus
# um; `restore` (undo) spielt beim Trennen das vorherige Layout zurück.
#
# Aufruf aus Sunshine:
#   sunshine-display-mode apply     # liest SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS
#   sunshine-display-mode restore   # undo
#   sunshine-display-mode show      # Debug: aktuelles Layout
#   sunshine-display-mode reset     # Notausgang: bevorzugter Modus
writeShellApplication {
  name = "sunshine-display-mode";
  runtimeInputs = [
    python3
    glib # gdbus
    coreutils
  ];
  text = ''
    exec ${python3}/bin/python3 ${./sunshine-display-mode.py} "$@"
  '';
  meta = {
    description = "Setzt den GNOME-Monitor auf die Auflösung des Moonlight-Clients";
    mainProgram = "sunshine-display-mode";
    platforms = lib.platforms.linux;
  };
}
