# kdbx-keychain: bidirektionaler Dropbox-Sync (rclone bisync) als User-Service.
#
# Quelle of Truth: Dropbox ↔ lokale Spiegel unter ~/Cloud/:
#   1. dropbox:kdbx-keychain/ ↔ ~/Cloud/kdbx-keychain/   (Test-Tresor)
#   2. dropbox:Apps/KeeWeb/   ↔ ~/Cloud/KeeWeb/          (echter Tresor + .key)
# GNOME Secrets liest/schreibt die lokale Kopie; die Browser-Extension spricht
# direkt mit der Dropbox-API — beide Seiten treffen sich in der Cloud.
#
# Creds sind komplett deklarativ: rclone-Config aus dem agenix-Secret
# rclone-kdbx-conf (client_id/secret + OAuth-Token); für manuelle rclone-
# Aufrufe setzt home.nix einen Symlink ~/.config/rclone/rclone.conf darauf.
#
# Erster Lauf pro Paar zieht bei leerer lokaler Seite die Dateien (Bootstrap)
# und macht danach automatisch `bisync --resync`, dann regulärer bisync.
{ pkgs, ... }:
let
  rclone = pkgs.rclone;
  syncScript = pkgs.writeShellScript "kdbx-rclone-bisync" ''
    set -euo pipefail
    [ -r /run/agenix/dropbox-keychain-env ] && source /run/agenix/dropbox-keychain-env
    # Deklarative Config aus agenix; Fallback: manuell gepflegte Datei
    if [ -r /run/agenix/rclone-kdbx-conf ]; then
      export RCLONE_CONFIG=/run/agenix/rclone-kdbx-conf
    else
      export RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
    fi
    STATE="$HOME/.local/share/kdbx-rclone"
    LOGDIR="$HOME/.local/state/kdbx-rclone"
    mkdir -p "$STATE" "$LOGDIR"
    LOG="$LOGDIR/bisync.log"
    # Dropbox rundet mtimes auf ganze Sekunden → 367ms-Drift gegenüber der
    # lokalen Nanosekunden-mtime, was bisync's Safety-Abort auslöst. Deshalb
    # size+checksum statt modtime; --download-hash, weil Dropbox kein MD5 hat
    # (Content-Hash wird per Download berechnet — Tresore sind winzig).
    ARGS=(--retries=2 --max-size 50M --compare size,checksum --download-hash
          --log-file "$LOG" --log-level INFO)
    # Paare: remote|lokal (| als Trenner, Pfade enthalten keine Pipe)
    PAIRS=(
      "''${RCLONE_REMOTE:-dropbox}:kdbx-keychain|$HOME/Cloud/kdbx-keychain"
      "''${KEEWEB_REMOTE:-dropbox}:Apps/KeeWeb|$HOME/Cloud/KeeWeb"
    )
    for pair in "''${PAIRS[@]}"; do
      REMOTE="''${pair%%|*}"
      LOCAL="''${pair##*|}"
      mkdir -p "$LOCAL"
      MARKER="$STATE/init-''${LOCAL//\//_}.done"
      # Bootstrap (Erst-Verknüpfung): lokale Seite leer → Cloud-Kopie ziehen
      if [ -z "$(ls -A "$LOCAL")" ]; then
        ${rclone}/bin/rclone copy "$REMOTE" "$LOCAL" || true
      fi
      if [ ! -f "$MARKER" ]; then
        ${rclone}/bin/rclone bisync "''${ARGS[@]}" --resync "$REMOTE" "$LOCAL"
        touch "$MARKER"
      else
        ${rclone}/bin/rclone bisync "''${ARGS[@]}" "$REMOTE" "$LOCAL"
      fi
    done
  '';
in
{
  systemd.user.services.kdbx-rclone-sync = {
    Unit = {
      Description = "kdbx-keychain: Dropbox ↔ ~/Cloud/kdbx-keychain (rclone bisync)";
      After = "graphical-session.target";
    };
    Service = {
      Type = "oneshot";
      ExecStart = syncScript;
    };
  };

  systemd.user.timers.kdbx-rclone-sync = {
    Unit.Description = "kdbx-keychain Sync-Timer (alle 5 Minuten)";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
