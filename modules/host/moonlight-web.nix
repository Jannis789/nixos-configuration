# Moonlight-Web-Stream — Browser-Client für den Sunshine-Host auf diesem
# Rechner, erreichbar unter https://jannis.nix-dev.link/stream/.
#
# Architektur:
#   Browser ⇄ nginx (TLS, Authelia, /stream/) ⇄ web-server (127.0.0.1:8080,
#   --path-prefix /stream) ⇄ Sunshine (127.0.0.1, GameStream-Protokoll)
#   Video/Audio: WebRTC, UDP 40000-40100 direkt zum Browser.
#
# Warum das und nicht der native Moonlight-Client: gleiche Technik (der
# Server linkt moonlight-common-c), aber ohne Client-Installation — und
# dieselben drei Anforderungen wie Sunshine bleiben erfüllt, weil Sunshine
# weiterhin der Host ist (inkl. Vaapi-Encode und sunshine-display-mode für
# die Auflösung).
#
# Wichtig für das Subpath-Setup:
#   * --path-prefix /stream  → ALLE Routen (Assets, /api, WebSocket) liegen
#     unter /stream; das Frontend lädt seine Assets relativ.
#   * nginx proxyPass OHNE URI-Teil, sonst wird der Präfix gestrippt.
#   * --forwarded-header Remote-User: der nginx setzt den Header nach
#     erfolgreicher Authelia-Auth; moonlight-web legt den Nutzer beim ersten
#     Request an (der ERSTE wird Admin). Kein eigenes Login nötig.
#
# Netz: WebRTC braucht UDP 40000-40100 und funktioniert hinter NAT nur mit
# STUN (Standard aktiv) oder TURN. Wenn die Verbindung nicht zustande kommt,
# im Web-UI "Data Transport → Web Sockets" wählen — dann läuft alles über
# 443/nginx (langsamer, aber firewallfest).
{ pkgs, lib, ... }:
let
  moonlightWeb = pkgs.callPackage ../../packages/moonlight-web.nix { };

  stateDir = "/var/lib/moonlight-web";

  webrtcPortRange = "40000:40100";
in
{
  systemd.services.moonlight-web = {
    description = "Moonlight-Web-Stream — Sunshine-Client für den Browser (/stream/)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        "${moonlightWeb}/lib/moonlight-web/web-server"
        "--bind-address 127.0.0.1:8080"
        # Sämtliche Routen unter /stream (nginx reicht den Pfad unverändert
        # durch, siehe modules/host/nginx.nix).
        "--path-prefix /stream"
        # Auth über den Reverse Proxy: nginx setzt Remote-User nach Authelia.
        "--forwarded-header Remote-User"
        "--webrtc-port-range ${webrtcPortRange}"
        "--config-path ${stateDir}/server/config.json"
      ];

      # `static/` wird relativ zum CWD geladen (tmpfiles-Symlink unten),
      # alles Schreibbare (config.json, DB) landet daneben im State-Dir.
      WorkingDirectory = stateDir;
      StateDirectory = "moonlight-web";
      StateDirectoryMode = "0750";

      User = "moonlight-web";
      Group = "moonlight-web";

      Restart = "on-failure";
      RestartSec = "5";
      # Der Dienst soll nicht auf die Gnome-Session warten — er braucht nur
      # Netz zu Sunshine auf localhost.
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ stateDir ];
    };
  };

  users.users.moonlight-web = {
    isSystemUser = true;
    group = "moonlight-web";
    home = stateDir;
    description = "Moonlight-Web-Stream";
  };
  users.groups.moonlight-web = { };

  systemd.tmpfiles.rules = [
    # Frontend-Assets aus dem Store in das (beschreibbare) Arbeitsverzeichnis
    # spiegeln — der Server sucht sie als ./static relativ zum CWD.
    "L+ ${stateDir}/static - - - - ${moonlightWeb}/lib/moonlight-web/static"
    "d ${stateDir}/server 0750 moonlight-web moonlight-web -"
  ];

  # WebRTC-Medien: UDP-Portbereich, den der Server selbst belegt.
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 40000;
      to = 40100;
    }
  ];
}
