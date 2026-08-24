{ config, lib, ... }:
{
  # prodress (4GL) — Hub-Verzeichnis, Executables und Java-Client.
  # Vars: EXECDIR/EXECDIR_BASE werden von pdbuild/check.sh gebraucht,
  # PRODRESSCLIENTDIR von der pd-Client-Logik.
  home.sessionVariables = {
    EXECDIR = "${config.home.homeDirectory}/hub/bin";
    EXECDIR_BASE = "${config.home.homeDirectory}/hub";
    PRODRESSCLIENTDIR = "${config.home.homeDirectory}/hub/javaclient";
  };
}
