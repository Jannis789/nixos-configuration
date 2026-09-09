{
  config,
  pkgs,
  lib,
  secrets,
  inputs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  # CachyOS-Kernel (x86_64-linux, aus dem cachyos-kernel-Input)
  boot.kernelPackages =
    inputs.cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest;

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };

  networking.hostName = "jannis";
  networking.networkmanager.enable = true;

  # WoL: nur Magic-Packet (wol g). Bewusst OHNE Extra-Service mit ExecStop —
  # der hatte beim Shutdown noch ethtool angefasst (Endlos-Boot-Verdacht).
  # ponytail: falls die Kiste nach Shutdown sofort wieder aufwacht, im BIOS
  # auf "Magic Packet only" stellen (kein Pattern/Broadcast-Wake).
  networking.interfaces.enp6s0.wakeOnLan.enable = true;

  # Tailscale für Remote-Zugriff von überall
  services.tailscale.enable = true;

  # Remote-Zugriff über jannis.nix-dev.link (DNS-only, Fritzbox-Portfreigabe):
  # 22  = SSH, 3389 = GNOME Remote Desktop (RDP)
  networking.firewall.allowedTCPPorts = [ 22 3389 ];

  # GNOME Remote Desktop (RDP :3389) — läuft als User-Service der eingeloggten
  # Session. Muss einmalig in GNOME Settings > Sharing > Remote Desktop
  # aktiviert + Passwort gesetzt werden.
  services.gnome.gnome-remote-desktop.enable = true;

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
    ethtool
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

  # Web-Dashboard: Restart, Power-Off, Terminal — HTTPS auf :443
  services.cockpit = {
    enable = true;
    port = 443;
    openFirewall = true;
    # Origin ohne Port — Browser sendet bei 443 keine Portnummer
    allowed-origins = [ "https://jannis.nix-dev.link" "https://localhost" ];
  };
  # Let's Encrypt via security.acme (auto-erneuernd per Timer). DNS-01-Challenge über
  # Cloudflare-DNS-API → kein offener Port 80, bleibt DNS-only für SSH/RDP.
  security.acme = {
    acceptTerms = true;
    defaults.email = "jannis@nix-dev.link"; # LE-Account; für Ablauf-Hinweise
    certs."jannis.nix-dev.link" = {
      domain = "jannis.nix-dev.link";
      dnsProvider = "cloudflare";
      environmentFile = "/run/acme/cloudflare-credentials";
      postRun = "systemctl try-restart cockpit.service --no-block";
    };
  };
  # ponytail: /run/acme wird vom acme-Modul (acme-setup) erzeugt; hier erst anlegen + nachlaufen lassen.
  # Credentials für die ACME-DNS-Challenge (tmpfs → bei jedem Boot neu).
  system.activationScripts.acmeToken = lib.mkAfter ''
    install -d -m 0700 -o acme -g acme /run/acme
    printf 'CF_DNS_API_TOKEN=${secrets.CF_DNS_API_TOKEN}\n' > /run/acme/cloudflare-credentials
    chown acme:acme /run/acme/cloudflare-credentials
    chmod 600 /run/acme/cloudflare-credentials
  '';

  # Cockpit braucht die LE-Zertifikate als DATEIEN in ws-certs.d (kein Verzeichnis-Symlink).
  # Cockpit ist socket-aktiviert (Start erst bei Erstverbindung): RemainAfterExit-once beim Boot
  # reicht NICHT — cockpit-certificate-ensure legt sonst wieder self-signed an (= falsches Zert).
  # Daher vor JEDEM cockpit-Start frisch verlinken (Requires/Before, kein RemainAfterExit).
  systemd.services.cockpit-acme-tls = {
    description = "Link Let's Encrypt certs into cockpit ws-certs.d";
    before = [ "cockpit.service" ];
    requiredBy = [ "cockpit.service" ];
    after = [ "acme-jannis.nix-dev.link.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /etc/cockpit/ws-certs.d
      rm -f /etc/cockpit/ws-certs.d/0-self-signed.cert /etc/cockpit/ws-certs.d/0-self-signed.key
      ln -sf /var/lib/acme/jannis.nix-dev.link/cert.pem /etc/cockpit/ws-certs.d/10-acme.cert
      ln -sf /var/lib/acme/jannis.nix-dev.link/key.pem /etc/cockpit/ws-certs.d/10-acme.key
    '';
  };
  system.activationScripts.ddclientToken = ''
    echo -n "${secrets.CF_DNS_API_TOKEN}" > /run/ddclient-token
    chmod 600 /run/ddclient-token
  '';

  # DDNS: hält jannis.nix-dev.link auf der Public-IP (Fritzbox-Portfreigabe 443 → diese Kiste)
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
