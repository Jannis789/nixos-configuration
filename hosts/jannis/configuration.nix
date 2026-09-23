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
  # 443 = nginx (terminiert TLS, davor Cockpit direkt)
  networking.firewall.allowedTCPPorts = [ 22 3389 443 ];

  # GNOME Remote Desktop (RDP :3389) — Remote-Login über GDM (System-Dienst,
  # kein lokaler User-Login nötig). Der Modul liefert den gnome-remote-desktop-
  # Dienst; wantedBy stellt sicher, dass er beim Boot mit graphical.target
  # startet. Auth beim RDP-Login erfolgt über GDM mit den jannis-Credentials.
  services.gnome.gnome-remote-desktop.enable = true;
  systemd.services."gnome-remote-desktop" = {
    wantedBy = [ "graphical.target" ];
    restartIfChanged = false;
  };

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
    # Linger, damit der User-Service (vscode-insiders-web) ab Boot läuft,
    # ohne dass jemand lokal eingeloggt ist.
    linger = true;
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

    # nvim aus dem eigenen Nixvim-Flake: Editor + pi (AI-Terminal per <leader>d)
    inputs.nixvim.packages.${pkgs.system}.default

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
    rustdesk

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

  # Web-Dashboard: Restart, Power-Off, Terminal — laeuft jetzt HINTER nginx
  # (nginx terminiert TLS auf :443), daher loopback + Klartext, kein eigenes Zert.
  # UrlRoot = /cockpit: cockpit-ws strippt url_root vom Pfad, BEVOR es matcht
  # (cockpitwebserver.c: "self->path = path_copy + url_root->len"), deshalb
  # kollidiert der App-Pfad /cockpit/ nicht mit Cockpits interner API
  # (/cockpit/cockpit/socket). Verifiziert mit cockpit-ws --no-tls:
  # / -> 404, /cockpit/ -> 200, /cockpit/cockpit/socket -> 403 (nur Origin fehlt).
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = false; # nur nginx (127.0.0.1) spricht Cockpit an
    # Origin ohne Port — Browser sendet bei 443 keine Portnummer
    allowed-origins = [
      "https://jannis.nix-dev.link"
      "wss://jannis.nix-dev.link"
      "https://localhost"
    ];
    settings.WebService = {
      UrlRoot = "/cockpit";
      # nginx terminiert TLS -> Cockpit muss X-Forwarded-Proto glauben
      ProtocolHeader = "X-Forwarded-Proto";
      ForwardedForHeader = "X-Forwarded-For";
    };
  };

  # Laufzeit-Downloads ausführbar machen: serve-web (VS Code Web-UI) lädt
  # einen ungepatchten Microsoft-node nach; nix-ld ersetzt den Stub-Linker
  # (/lib64/ld-linux -> nix-ld) und reicht libc/libstdc++/zlib durch. Der
  # vscode-insiders-web-Service setzt NIX_LD(+LIBRARY_PATH) im Unit selbst.
  programs.nix-ld = {
    enable = true;
    libraries = [ (pkgs.lib.getLib pkgs.stdenv.cc.cc) pkgs.zlib ];
  };

  # SSO-Gate: einmal am Apex einloggen, alle Subrouten (/cockpit/, /pi-web/)
  # erben die Session per auth_request (Cookie auf .jannis.nix-dev.link).
  # Portal unter /authelia/ (Base-Path traegt Authelia selbst via
  # server.address), Verify unter /authelia-verify (internal, nur nginx).
  # Authelia-Credentials deklarativ aus secrets.nix (privates Single-User-Repo,
  # bewusst Klartext wie der Rest dort). NB: landet dadurch auch lesbar im
  # /nix/store — bei fremden Augen auf Host/Repo sofort auf sops-nix wechseln.
  # totp_secret vorab gesetzt => keine QR-Anmeldung noetig, Key direkt in die App.
  environment.etc = {
    "authelia/jwt-secret".text = secrets.AUTHELIA_JWT_SECRET;
    "authelia/storage-key".text = secrets.AUTHELIA_STORAGE_KEY;
    "authelia/users_database.yml".text = ''
      users:
        jannis:
          displayname: "Jannis"
          password: "${secrets.AUTHELIA_PASSWORD_HASH}"
          email: jannis@nix-dev.link
          groups: []
          totp_secret: ${secrets.AUTHELIA_TOTP_SECRET}
    '';
  };
  services.authelia.instances.main = {
    enable = true;
    secrets.jwtSecretFile = "/etc/authelia/jwt-secret";
    secrets.storageEncryptionKeyFile = "/etc/authelia/storage-key";
    settings = {
      theme = "auto";
      default_2fa_method = "totp";
      log.level = "info";
      server.address = "tcp://127.0.0.1:9091/authelia";
      totp.issuer = "jannis.nix-dev.link";
      authentication_backend.file = {
        path = "/etc/authelia/users_database.yml";
        password.algorithm = "argon2id";
      };
      access_control = {
        default_policy = "deny";
        rules = [
          { domain = "jannis.nix-dev.link"; policy = "two_factor"; }
        ];
      };
      session.cookies = [{
        domain = "jannis.nix-dev.link";
        default_redirection_url = "https://jannis.nix-dev.link/";
        authelia_url = "https://jannis.nix-dev.link/authelia";
        name = "authelia_session";
        same_site = "lax";
        expiration = "1h";
        inactivity = "5m";
      }];
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
    };
  };

  # Reverse-Proxy + WIP-Hub auf :443. "/" = statische Hub-Seite (./hub/),
  # "/cockpit/" = Cockpit.
  services.nginx = {
    enable = true;
    # gzip bricht Cockpits ETag-Handling (bekannter Cockpit-bei-Proxy-Fallstrick)
    recommendedGzipSettings = false;
    # liefert u.a. Host / X-Real-IP / X-Forwarded-For / X-Forwarded-Proto
    recommendedProxySettings = true;
    # Catch-all fuer alles, was nicht jannis.nix-dev.link ist: TLS-Handshake
    # wird abgewiesen (ssl_reject_handshake), statt den Apex-Vhost zu erben.
    # Faengt auch alte Hostnamen ab, die noch in DNS-Caches stecken.
    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      locations."/" = {
        return = "444"; # Port 80: Verbindung kommentarlos schliessen
      };
    };
    virtualHosts."jannis.nix-dev.link" = {
      forceSSL = true;
      useACMEHost = "jannis.nix-dev.link"; # Reload nach Renewal macht acme selbst
      root = ./hub;
      # Hub hinter dem Gate: ohne Session -> 302 zum Portal; nach Login immer Hub (default_redirection_url).
      locations."/" = {
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          add_header Cache-Control "no-cache" always; # Hub enthaelt Token-Fetch-JS: immer revalidieren (etag spart Traffic)
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      # Authelia-Portal (oeffentlich, KEIN auth_request — sonst Login-Loop).
      # Upstream kennt seinen Base-Path, daher Prefix strippen (trailing slash).
      locations."/authelia/" = {
        proxyPass = "http://127.0.0.1:9091/authelia/";
        proxyWebsockets = true;
      };
      locations."= /authelia" = {
        return = "302 /authelia/";
      };
      # Verify-Endpunkt fuer auth_request: internal, nur nginx ruft ihn auf.
      locations."/authelia-verify" = {
        extraConfig = ''
          internal;
          proxy_pass http://127.0.0.1:9091/authelia/api/verify;
          proxy_pass_request_body off;
          proxy_set_header Content-Length "";
          proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        '';
      };
      locations."/cockpit/" = {
        # KEIN trailing slash: Cockpit muss "/cockpit/..." sehen (entspricht UrlRoot)
        proxyPass = "http://127.0.0.1:9090";
        proxyWebsockets = true; # Cockpit-Terminal/Session laeuft ueber WebSocket
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
      # pi-web (http://127.0.0.1:8504, per-user Service): braucht KEINE
      # Prefix-Config — Prefix strippen reicht, Redirect /pi-web -> /pi-web/.
      locations."/pi-web/" = {
        proxyPass = "http://127.0.0.1:8504/";
        proxyWebsockets = true; # Terminals/Sessions laufen ueber WebSocket
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      locations."= /pi-web" = {
        return = "302 /pi-web/";
      };
      locations."/betterwright/" = {
        proxyPass = "http://127.0.0.1:8505/"; # betterwright view (Skill startet ihn auf Fixport 8505)
        proxyWebsockets = true; # Live-View-Steuerung laeuft ueber WebSocket
        extraConfig = ''
          auth_request /authelia-verify;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://$host/authelia/;
        '';
      };
      locations."= /betterwright" = {
        return = "302 /betterwright/";
      };
      # VS Code Insiders Web-UI (serve-web, User-Service auf 8506, base-path
      # /vscode): Prefix bleibt AM Proxy haengen (wie Cockpit/UrlRoot), weil
      # serve-web den vollen Pfad erwartet (--server-base-path).
      locations."/vscode/" = {
        proxyPass = "http://127.0.0.1:8506";
        proxyWebsockets = true; # Editor/Datei-Watcher laufen ueber WebSocket
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
      # Aktueller BetterWright-Token (Skill schreibt ihn hierhin; NICHT /tmp,
      # nginx läuft mit PrivateTmp) -> Hub-Kachel baut den klickbaren Link.
      locations."= /bw-url" = {
        extraConfig = ''
          auth_request /authelia-verify;
          error_page 401 =302 https://$host/authelia/;
          alias /var/lib/betterwright/view-url;
          default_type text/plain;
        '';
      };
    };
  };
  # BetterWright-Viewer-Token fuer die Hub-Kachel (nginx liest die Datei).
  systemd.tmpfiles.rules = [ "d /var/lib/betterwright 0755 jannis users -" ];
  # Let's Encrypt via security.acme (auto-erneuernd per Timer). DNS-01-Challenge über
  # Cloudflare-DNS-API → kein offener Port 80, bleibt DNS-only für SSH/RDP.
  security.acme = {
    acceptTerms = true;
    defaults.email = "jannis@nix-dev.link"; # LE-Account; für Ablauf-Hinweise
    certs."jannis.nix-dev.link" = {
      domain = "jannis.nix-dev.link";
      dnsProvider = "cloudflare";
      environmentFile = "/run/acme/cloudflare-credentials";
      # nginx liest das Zert; Renewal-Reload macht useACMEHost automatisch
      group = "nginx";
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

  # (cockpit-acme-tls entfaellt: Cockpit terminiert kein TLS mehr, nginx macht das.
  #  Der ws-certs.d-Symlink-Tanz gegen cockpit-certificate-ensure ist damit tot.)
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
