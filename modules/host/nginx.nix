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
      root = "/var/www/hub";
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
    };
  };
}
