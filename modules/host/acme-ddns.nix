{
  config,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "jannis@nix-dev.link";
    certs."jannis.nix-dev.link" = {
      domain = "jannis.nix-dev.link";
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-credentials.path;
      group = "nginx";
    };
  };

  services.ddclient = {
    enable = true;
    usev4 = "webv4, webv4=checkip.amazonaws.com";
    usev6 = "";
    protocol = "cloudflare";
    username = "token";
    passwordFile = config.age.secrets.cloudflare-token.path;
    zone = "nix-dev.link";
    domains = [ "jannis.nix-dev.link" ];
    interval = "5min";
  };
  systemd.services.ddclient = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
