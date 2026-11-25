# kdbx-keychain: bidirektionaler Dropbox-Sync (rclone bisync) als User-Service.
#
# Quelle of Truth: dropbox:kdbx-keychain/ ↔ ~/Cloud/kdbx-keychain/
# GNOME Secrets liest/schreibt die lokale Kopie; die Browser-Extension spricht
# direkt mit der Dropbox-API — beide Seiten treffen sich in der Cloud.
#
# Dropbox-Creds: aus dem agenix-Secret (export-Zeilen), damit rate limits
# unserem App-Key zugeordnet werden. OAuth-Token: ~/.config/rclone/rclone.conf
# (chmod 600, liegt außerhalb aller Repos).
#
# Erster Lauf macht automatisch `bisync --resync`, danach regulärer bisync.
{ pkgs, ... }:
let
  syncScript = pkgs.writeShellScript "kdbx-rclone-bisync" ''
    set -euo pipefail
    [ -r /run/agenix/dropbox-keychain-env ] && source /run/agenix/dropbox-keychain-env
    export RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
    STATE="$HOME/.local/share/kdbx-rclone"
    LOGDIR="$HOME/.local/state/kdbx-rclone"
    mkdir -p "$STATE" "$LOGDIR"
    LOG="$LOGDIR/bisync.log"
    REMOTE="''${RCLONE_REMOTE:-dropbox}:kdbx-keychain"
    ARGS=(--retries=2 --max-size 50M --log-file "$LOG" --log-level INFO)
    if [ ! -f "$STATE/bisync-init.done" ]; then
      ${pkgs.rclone}/bin/rclone bisync "''${ARGS[@]}" --resync "$REMOTE" "$HOME/Cloud/kdbx-keychain"
      touch "$STATE/bisync-init.done"
    else
      ${pkgs.rclone}/bin/rclone bisync "''${ARGS[@]}" "$REMOTE" "$HOME/Cloud/kdbx-keychain"
    fi
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
