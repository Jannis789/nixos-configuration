{ pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  systemd.targets.suspend.enable = false;
  systemd.targets.sleep.enable = false;

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    ethtool
    gjs
    epiphany
    helium
    fragments
    # kdbx-keychain (Phase 5): Desktop-Client für die KDBX auf Dropbox
    # (lokal synchronisiert via rclone, siehe ~/Cloud/kdbx-keychain)
    gnome-secrets
    rustdesk
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    # gnomeExtensions.customize-clock-on-lock-screen # deprecated
    gnomeExtensions.native-screenshot-ui-ocr-extended
    gnomeExtensions.hanabi
    # gnomeExtensions.user-themes # TODO: currently unsupported
    gnomeExtensions.color-picker
    gnomeExtensions.astra-monitor
    gnomeExtensions.dash-to-dock

    (tesseract5.override {
      enableLanguages = [
        "deu"
        "eng"
      ];
    })
  ];
}
