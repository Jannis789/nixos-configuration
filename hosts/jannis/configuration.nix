{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };

  networking.hostName = "jannis";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  users.users.jannis = {
    isNormalUser = true;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [ (builtins.readFile ./keys/lannitz.pub) ]; # wonko (macOS)
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    helium

    epiphany

    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.customize-clock-on-lock-screen
    gnomeExtensions.native-screenshot-ui-ocr-extended
    gnomeExtensions.hanabi
    gnomeExtensions.user-themes
    gnomeExtensions.color-picker
    gnomeExtensions.astra-monitor
    gnomeExtensions.dash-to-dock

    (tesseract5.override {
      enableLanguages = [
        "deu"
        "eng"
      ];
    })

    gjs
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # Web-Dashboard: Restart, Power-Off, Terminal — HTTPS auf :9000
  services.cockpit = {
    enable = true;
    port = 443;
    openFirewall = true;
    # Origin ohne Port — Browser sendet bei 443 keine Portnummer
    allowed-origins = [ "https://jannis.nix-dev.link" "https://localhost" ];
  };
  # Let's Encrypt per DNS-01 (Cloudflare) — echte Domain statt Self-Signed
  security.acme = {
    acceptTerms = true;
    defaults.email = "jrustige@prodress.de";
    certs."jannis.nix-dev.link" = {
      # ponytail: Cockpit 366 DynamicUser-Gruppe ist nicht statisch — lesbar via other-Bits statt chown
      group = "nogroup";
      postRun = "chmod 755 /var/lib/acme/jannis.nix-dev.link; chmod 644 /var/lib/acme/jannis.nix-dev.link/*";
      dnsProvider = "cloudflare";
      # ponytail: Runtime-Datei statt sops — Token kommt aus secrets.nix
      environmentFile = "/run/acme-cloudflare-creds";
    };
  };
  system.activationScripts.acmeCloudflareCreds = ''
    echo "CF_DNS_API_TOKEN=${secrets.CF_DNS_API_TOKEN}" > /run/acme-cloudflare-creds
    chmod 600 /run/acme-cloudflare-creds
    echo -n "${secrets.CF_DNS_API_TOKEN}" > /run/ddclient-token
    chmod 600 /run/ddclient-token
  '';

  # DDNS: hält jannis.nix-dev.link auf der Public-IP (Fritzbox-Portfreigabe 443 → diese Kiste)
  services.ddclient = {
    enable = true;
    use = "web, web=checkip.amazonaws.com";
    protocol = "cloudflare";
    username = "token";
    passwordFile = "/run/ddclient-token";
    zone = "nix-dev.link";
    domains = [ "jannis.nix-dev.link" ];
    interval = "5min";
    extraConfig = ''
      # ponytail: Boot-Rennen — startet zu früh ohne Netzwerk, retry bis online
    '';
  };
  systemd.services.ddclient = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
  environment.etc."cockpit/ws-certs.d/10-jannis-nix-dev-link.cert".source =
    config.security.acme.certs."jannis.nix-dev.link".directory + "/fullchain.pem";
  environment.etc."cockpit/ws-certs.d/10-jannis-nix-dev-link.key".source =
    config.security.acme.certs."jannis.nix-dev.link".directory + "/key.pem";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://cache.nixos.org" ];
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.11";
}
