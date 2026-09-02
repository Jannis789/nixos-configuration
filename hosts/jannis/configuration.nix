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

  # Wake-on-LAN für enp6s0 (aus der Legacy-Config übernommen)
  networking.interfaces.enp6s0.wakeOnLan.enable = true;

  # Service setzt WoL beim Boot und nochmal beim Shutdown (ExecStop),
  # weil manche Treiber die Einstellung beim Herunterfahren verlieren.
  systemd.services.wake-on-lan = {
    description = "Enable WoL on enp6s0";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp6s0 wol g";
      ExecStop = "${pkgs.ethtool}/bin/ethtool -s enp6s0 wol g";
    };
  };

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

  # Web-Dashboard: Restart, Power-Off, Terminal — HTTPS auf :9000
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
      postRun = "systemctl try-restart cockpit --no-block";
    };
  };
  # ponytail: /run/acme wird vom acme-Modul (acme-setup) erzeugt; hier erst anlegen + nachlaufen lassen.
  system.activationScripts.acmeToken = lib.mkAfter ''
    install -d -m 0700 -o acme -g acme /run/acme
    install -m 0600 /dev/null /run/acme/cloudflare-credentials
    cat > /run/acme/cloudflare-credentials <<EOF
CF_DNS_API_TOKEN=${secrets.CF_DNS_API_TOKEN}
EOF
    rm -f /etc/cockpit/ws-certs.d/*.cert /etc/cockpit/ws-certs.d/*.key
    ln -sf /var/lib/acme/jannis.nix-dev.link/cert.pem /etc/cockpit/ws-certs.d/10-acme.cert
    ln -sf /var/lib/acme/jannis.nix-dev.link/key.pem /etc/cockpit/ws-certs.d/10-acme.key
  '';
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
