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

      # Moonlight-Web-Stream unter /stream/ — Browser-Client für den
      # Sunshine-Host (modules/host/moonlight-web.nix). Kein eigenes
      # Subdomain-VHost: der hätte einen manuellen CNAME in Cloudflare
      # gebraucht (deshalb war stream.jannis.nix-dev.link damals NXDOMAIN);
      # außerdem braucht der Browser einen Secure Context — TLS terminiert
      # hier der Haupt-VHost, und die Gamepad-/Keyboard-Lock-/Clipboard-APIs
      # sind damit verfügbar.
      #
      # Der Upstream läuft mit --path-prefix /stream und erwartet den Präfix
      # IM Pfad: proxyPass hier bewusst OHNE URI-Teil, damit nginx /stream/…
      # unverändert an 127.0.0.1:8080 durchreicht (ein "http://…:8080/" mit
      # Slash würde den Präfix strippen und alles auf / 404en).
      # proxyWebsockets ist Pflicht: über /stream/api/host/stream/web_socket
      # wird der WebRTC-Handshake geführt. Remote-User/Remote-Email gehen als
      # Authentifizierung an moonlight-web (--forwarded-header Remote-User),
      # damit dort kein zweites Login nötig ist.
      locations."/stream/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
          proxy_buffering off;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        '';
      };
      locations."= /stream" = {
        return = "302 /stream/";
      };
    };
  };
}
