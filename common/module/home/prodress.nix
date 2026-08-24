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

  # Log-Symlinks: ~/workspace/sswsh.log + dbrte-log -> ~/hub (AGENTS.md).
  # Out-of-store: die Logs ändern sich laufend, also echte Symlinks statt
  # Store-Kopien.
  home.file = {
    "workspace/sswsh.log".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/hub/sswsh.log";
    "workspace/dbrte-log".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/hub/dbrte-log";
  };

  # pmake = pdbuild aus dem prodressnet-Baum (ersetzt den alten .zshrc-Alias).
  # prodress: "cd /pfad/zu/4gl/folder && pmake <modul>" — pdbuild findet das
  # Modulverzeichnis selbst. Nicht-interaktive Shells: bash -ic "pmake <modul>".
  home.shellAliases = {
    pmake = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild";
    pmakeclean = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild -t clean";
  };
}
