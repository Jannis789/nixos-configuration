{
  lib,
  secrets,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "jannis@nix-dev.link";
    certs."jannis.nix-dev.link" = {
      domain = "jannis.nix-dev.link";
      dnsProvider = "cloudflare";
      environmentFile = "/run/acme/cloudflare-credentials";
      group = "nginx";
    };
  };

  system.activationScripts.acmeToken = lib.mkAfter ''
    install -d -m 0700 -o acme -g acme /run/acme
    printf 'CF_DNS_API_TOKEN=${secrets.CF_DNS_API_TOKEN}\n' > /run/acme/cloudflare-credentials
    chown acme:acme /run/acme/cloudflare-credentials
    chmod 600 /run/acme/cloudflare-credentials
  '';

  system.activationScripts.ddclientToken = ''
    echo -n "${secrets.CF_DNS_API_TOKEN}" > /run/ddclient-token
    chmod 600 /run/ddclient-token
  '';

  services.ddclient = {
    enable = true;
    usev4 = "webv4, webv4=checkip.amazonaws.com";
    usev6 = "";
    protocol = "cloudflare";
    username = "token";
    passwordFile = "/run/ddclient-token";
    zone = "nix-dev.link";
    domains = [ "jannis.nix-dev.link" ];
    interval = "5min";
  };
  systemd.services.ddclient = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
