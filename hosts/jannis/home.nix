{
  secrets,
  pkgs,
  betterfox,
  lib,
  config,
  ...
}:
let
  # Firefox Dev Edition: deklarativer DEV-Browser für kdbx-keychain.
  # Release-Firefox lehnt unsignde XPIs ab (auch per Policy — empirisch
  # ERROR_SIGNEDSTATE_REQUIRED, Nov 2026). Dev Edition erlaubt sie, braucht
  # aber das explizite pref (extraPrefs); die Policy installiert die XPI aus
  # dem Workspace-Build neu, sobald sich die Datei ändert. Dev-Loop:
  #   kdbx-workspace: scripts/dev-install.sh  →  firefox-devedition neu starten
  # Bewusst NICHT über programs.firefox — Release-Browser und -Profil bleiben
  # unangetastet. Produktion (signierte XPI via AMO) siehe unten.
  firefox-dev-edition = pkgs.firefox-devedition-bin.override {
    extraPrefs = ''
      pref("xpinstall.signatures.required", false);
    '';
    extraPolicies = {
      ExtensionSettings = {
        "kdbx-keychain@nix-dev.link" = {
          installation_mode = "force_installed";
          install_url =
            "file://${config.home.homeDirectory}/workspace/kdbx-keychain-extension/packages/extension/dist/firefox/kdbx-keychain-dev.xpi";
        };
      };
    };
  };
in
{
  home.username = "jannis";
  home.homeDirectory = "/home/jannis";
  home.stateVersion = "26.11";

  imports = [
    ../../modules/atuin.nix
    ../../modules/font.nix
    ../../modules/theme.nix
    ../../modules/gnome
    ../../modules/goose.nix
    ../../modules/heron.nix
    ../../modules/solid-skills.nix
    ../../modules/ssh.nix
    ../../modules/starship.nix
    ../../modules/terminal-browser.nix
    ../../modules/vscode-insiders.nix
    ../../modules/workspace.nix
    # kdbx-keychain: Dropbox ↔ lokale Kopie (rclone bisync), siehe ~/Cloud/kdbx-keychain
    ../../modules/rclone-kdbx.nix
  ];

  # ── kdbx-keychain: deklarative Verknüpfungen ──────────────────────────────
  # rclone-Creds leben im agenix-Secret (kein Klartext in $HOME). Der Symlink
  # macht die Config für manuelle rclone-Aufrufe lesbar; der bisync-Service
  # nutzt den agenix-Pfad direkt (siehe modules/rclone-kdbx.nix).
  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/rclone/rclone.conf - - - - /run/agenix/rclone-kdbx-conf"
    "L+ %h/.local/share/kdbx-keychain/export.key - - - - /run/agenix/kdbx-export-key"
  ];

  # GNOME Secrets öffnet beim Login den echten Tresor („always open“ ab
  # Anmeldung, ADR-004: Master-Passwort + Keyfile-Auswahl pro Session).
  # Dateipfad = rclone-Spiegel von dropbox:Apps/KeeWeb/ (modules/rclone-kdbx.nix).
  xdg.configFile."autostart/kdbx-secrets.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Secrets (kdbx-keychain)
    Exec=${pkgs.gnome-secrets}/bin/secrets /home/jannis/Cloud/KeeWeb/export.kdbx
    Icon=org.gnome.World.Secrets
    Terminal=false
    NoDisplay=true
    X-GNOME-Autostart-enabled=true
  '';

  # GNOME Secrets deklarativ: echten Tresor + Keyfile verknüpfen.
  # Wertformat laut gsecrets-Quelle (config_manager.py + provider/file_provider.py):
  #   last-used-key-provider = { <db-uri>: <json "{FileProvider: {url: <keyfile-uri>}}> }
  #   remember-composite-key = true → Unlock-Dialog stellt das Keyfile automatisch ein
  # (nur das Keyfile wird vorgeladen — das Master-Passwort bleibt naturgemäß manuell).
  dconf.settings."org/gnome/World/Secrets" = {
    last-opened-database = "file:///home/jannis/Cloud/KeeWeb/export.kdbx";
    last-opened-list = [ "file:///home/jannis/Cloud/KeeWeb/export.kdbx" ];
    remember-composite-key = true;
    remember-unlock-method = true;
    last-used-key-provider = builtins.toJSON {
      "file:///home/jannis/Cloud/KeeWeb/export.kdbx" = builtins.toJSON {
        # Plain-Path (kein file://) — exakt das Format, das gsecrets selbst schreibt;
        # Quelle = agenix-Deployment (siehe tmpfiles-Regel oben), nicht die bisync-Kopie
        FileProvider.url = "/home/jannis/.local/share/kdbx-keychain/export.key";
      };
    };
  };

  programs.bash.enable = true;

  # Firefox: KDBX-Keychain per Enterprise-Policy (deklarativ statt
  # about:debugging-Gefrickel). Firefox-Release installiert KEINE unsignden
  # XPIs per Policy (ERROR_SIGNEDSTATE_REQUIRED) — deshalb signiert
  # `scripts/sign-firefox.sh` (kdbx-keychain-Workspace) per AMO unlisted.
  # Sobald die signierte XPI im Repo liegt, aktiviert sich die Policy beim
  # Rebuild automatisch; vorher ist der Block eval-neutral ausgeblendet.
  # allowed_permissions grantet optional_host_permissions (<all_urls>)
  # deklarativ — kein manuelles Permission-Toggling in about:addons.
  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = lib.optionalAttrs
        (builtins.pathExists (../../packages + "/kdbx-keychain.xpi"))
        {
          "kdbx-keychain@nix-dev.link" = {
            installation_mode = "force_installed";
            install_url = "file://${../../packages + "/kdbx-keychain.xpi"}";
            allowed_permissions = [ "<all_urls>" ];
          };
        };
    };
    profiles."default" = {
      extraConfig = builtins.readFile "${betterfox}/user.js" + ''

        /* Stylix-/Theme-Prefs nachziehen (Firefox-GNOME-Theme + base16) */
        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        user_pref("svg.context-properties.content.enabled", true);
      '';
    };
    configPath = ".mozilla/firefox";
  };

  programs.bash.initExtra = ''
    unset __HM_SESS_VARS_SOURCED
    . "$HOME/.local/state/home-manager/gcroots/current-home/home-path/etc/profile.d/hm-session-vars.sh"
    if [ -r /run/agenix/api-keys-env ]; then . /run/agenix/api-keys-env; fi
    fastfetch
  '';

  programs.vscode-insiders = {
    enable = true;
    serveWeb = {
      enable = true;
      defaultFolder = "/home/jannis/workspace";
    };
  };

  programs.terminal-browser.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "jannis";
      email = "jannis@nix-dev.link";
    };
  };

  home.file.".ssh/authorized_keys".text = secrets.SSH_KEYS.lannitz.public + "\n";

  home.packages = with pkgs; [
    firefox-dev-edition
    ghostty
    fastfetch
  ];

  # API-Keys kommen aus dem age-Secret "api-keys-env" und werden in
  # programs.bash.initExtra aus /run/agenix/api-keys-env gesourced.
}
