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

  # Tailscale für Remote-Zugriff von überall
  services.tailscale.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  users.users.jannis = {
    isNormalUser = true;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [ secrets.SSH_KEYS.lannitz.public ]; # wonko (macOS)
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

  # Server (Cockpit :443) — nie suspendieren. dconf allein reicht nicht: im Login-Screen
  # (kein User eingeloggt) suspendiert der gdm-greeter per gsd-power nach 15 min Idle.
  # Der frühere No-Op-Hack (systemd-suspend → true) lies logind den Suspend "erfolgreich"
  # durchlaufen: GDM stürzte danach ab → Auto-Login + gnome-session-ReBoot (2026-08-26 06:29).
  # Stattdessen suspend/sleep.target entfernen → Suspend-Anfrage schlägt fehl, kein sleep-Dance.
  systemd.targets.suspend.enable = false;
  systemd.targets.sleep.enable = false;

  # Web-Dashboard: Restart, Power-Off, Terminal — HTTPS auf :9000
  services.cockpit = {
    enable = true;
    port = 443;
    openFirewall = true;
    # Origin ohne Port — Browser sendet bei 443 keine Portnummer
    allowed-origins = [ "https://jannis.nix-dev.link" "https://localhost" ];
  };
  # Cloudflare Origin CA (bis 2041) — signiert für *.nix-dev.link / nix-dev.link.
  # ACHTUNG: Origin-CA ist NICHT im Browser-Trust-Store. Direkter Zugriff (ohne Cloudflare-Proxy)
  # zeigt weiterhin die Zertifikatswarnung; dann ist öffentlich vertrautes Let's Encrypt (security.acme)
  # die richtige Wahl. Origin-CA ist korrekt, wenn die Domain hinter Cloudflare proxyed.
  environment.etc = {
    "cockpit/ws-certs.d/10-cloudflare-origin.cert" = {
      text = secrets.COCKPIT_ORIGIN_CERT;
      mode = "0644";
    };
    "cockpit/ws-certs.d/10-cloudflare-origin.key" = {
      text = secrets.COCKPIT_ORIGIN_KEY;
      mode = "0600";
    };
  };
  system.activationScripts.ddclientToken = ''
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
  };
  # ponytail: Boot-Rennen — ddclient startet zu früh ohne Netzwerk; auf network-online warten
  systemd.services.ddclient = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://cache.nixos.org" ];
  };

  system.stateVersion = "26.11";
}
