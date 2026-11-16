{ ... }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = false;
    allowed-origins = [
      "https://jannis.nix-dev.link"
      "wss://jannis.nix-dev.link"
      "https://localhost"
    ];
    settings.WebService = {
      UrlRoot = "/cockpit";
      ProtocolHeader = "X-Forwarded-Proto";
      ForwardedForHeader = "X-Forwarded-For";
    };
  };
}
