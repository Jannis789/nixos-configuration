{ ... }:
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = false;
    recommendedProxySettings = true;

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      locations."/" = {
        return = "444";
      };
    };

    virtualHosts."jannis.nix-dev.link" = {
      forceSSL = true;
      useACMEHost = "jannis.nix-dev.link";
      # Hub-Dashboard deklarativ aus dem Store (assets/hub/index.html)
      root = "${../../assets/hub}";
      locations."/" = {
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          add_header Cache-Control "no-cache" always;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      locations."/authelia/" = {
        proxyPass = "http://127.0.0.1:9092/authelia/";
        proxyWebsockets = true;
      };
      locations."= /authelia" = {
        return = "302 /authelia/";
      };
      locations."/authelia-verify" = {
        extraConfig = ''
          internal;
          proxy_pass http://127.0.0.1:9092/authelia/api/verify;
          proxy_pass_request_body off;
          proxy_set_header Content-Length "";
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        '';
      };
      locations."/cockpit/" = {
        proxyPass = "http://127.0.0.1:9090";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      locations."/vscode/" = {
        proxyPass = "http://127.0.0.1:8506";
        proxyWebsockets = true;
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      locations."= /vscode" = {
        return = "302 /vscode/";
      };

      # /stream/ (Selkies) ist am 2026-11-24 abgeschaltet: Selkies kann keine
      # adaptive Auflösung und teilt sich mit Sunshine dieselbe (einzige)
      # RemoteDesktop-Session von mutter — zwei Tools am selben Port wären
      # wieder die "drei halben Lösungen". Streaming läuft jetzt über
      # Sunshine/Moonlight (modules/host/sunshine.nix), das Web-UI von
      # Sunshine bleibt LAN-only auf Port 47990 (SSH-Tunnel, kein nginx).
      # Wer Selkies zurückholen will: modules/host/selkies.nix wieder in
      # modules/host/default.nix importieren UND diesen Block reaktivieren:
      #
      #   locations."/stream/" = {
      #     proxyPass = "http://127.0.0.1:8080";   # ohne URI-Teil: Präfix bleibt
      #     proxyWebsockets = true;
      #     extraConfig = ''
      #       auth_request /authelia-verify;
      #       proxy_buffering off;
      #       proxy_read_timeout 3600s;
      #     '';
      #   };
      #   locations."= /stream" = { return = "302 /stream/"; };
    };
  };
}
