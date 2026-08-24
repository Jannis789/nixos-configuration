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
    "workspace/sswsh.log".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/hub/sswsh.log";
    "workspace/dbrte-log".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/hub/dbrte-log";
  };

  # pmake = pdbuild aus dem prodressnet-Baum (ersetzt den alten .zshrc-Alias).
  # prodress: "cd /pfad/zu/4gl/folder && pmake <modul>" — pdbuild findet das
  # Modulverzeichnis selbst. Nicht-interaktive Shells: bash -ic "pmake <modul>".
  # pmake = pdbuild aus dem prodressnet-Baum (ersetzt den alten .zshrc-Alias).
  # prodress: "cd /pfad/zu/4gl/folder && pmake <modul>" — pdbuild findet das
  # Modulverzeichnis selbst. Nicht-interaktive Shells: bash -ic "pmake <modul>".
  #
  # instXX/deinstXX: updater.sh auf den ASP-Servern (aus .zshrc.backup-vor-
  # home-manager). inst = deploy (-arg p), deinst = remove (-arg r). Das
  # Skript liegt auf dem Server — die Aliase sind reine SSH-Aufrufe.
  home.shellAliases = {
    pmake = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild";
    pmakeclean = "${config.home.homeDirectory}/workspace/prodress/prodressnet/pdbuild -t clean";

    inst22c = "ssh asp22c.prodress-updates.de -l prodress hub/bin/updater.sh -arg p -arg";
    inst24a = "ssh asp24a.prodress.vpn -l prodress hub/bin/updater.sh -arg p -arg";
    inst24b = "ssh asp24b.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    inst25a = "ssh asp25a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    inst26a = "ssh asp26a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg p -arg";
    instTest = "ssh magrathea.prodress.vpn -l prodress testserver/bin/updater.sh -arg p -arg";

    deinst23a = "ssh asp23a.prodress.vpn -l prodress hub/bin/updater.sh -arg r -arg";
    deinst24a = "ssh asp24a.prodress.vpn -l prodress hub/bin/updater.sh -arg r -arg";
    deinst24b = "ssh asp24b.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinst25a = "ssh asp25a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinst26a = "ssh asp26a.prodress.vpn -4 -l prodress hub/bin/updater.sh -arg r -arg";
    deinstTest = "ssh magrathea.prodress.vpn -l prodress testserver/bin/updater.sh -arg r -arg";
  };
}
