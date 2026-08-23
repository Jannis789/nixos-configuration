{ config, lib, pkgs, ... }:
{
  # GNOME Extensions: Installation im System-Store (configuration.nix), damit die
  # GDM/GNOME-Session sie über XDG_DATA_DIRS findet (HM-Profil ist unsichtbar).
  # Diese Datei verwaltet nur Aktivierung + Settings.

  dconf.settings."org/gnome/shell" = {
    # Leere disabled-Liste: GNOME hatte hier alte manuelle Deaktivierungen,
    # die über enabled-extensions gewinnen und alles ausgeschaltet lassen.
    disabled-extensions = [ ];

    enabled-extensions = [
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "color-picker@tuberry"
      "blur-my-shell@aunetx"
      "caffeine@patapon.info"
      "monitor@astraext.github.io"
      "dash-to-dock@micxgx.gmail.com"
      "CustomizeClockOnLockScreen@pratap.fastmail.fm"
      "clipboard-indicator@tudmotu.com"
      "ocr-to-clipboard@oreocapybara"
    ];
  };

  # dash-to-dock: Metro-Indikator, fester Hintergrund (20% Deckkraft)
  dconf.settings."org/gnome/shell/extensions/dash-to-dock" = {
    running-indicator-style = "METRO";
    background-opacity = 0.2;
    transparency-mode = "FIXED";
  };

  # blur-my-shell Panel: Weicher Blur (sigma 20), kein statischer Blur
  dconf.settings."org/gnome/shell/extensions/blur-my-shell/panel" = {
    sigma = 20;
    static-blur = false;
  };

  # clipboard-indicator: Super+V öffnet direkt den Clipboard-Mode (Menü + Suche)
  dconf.settings."org/gnome/shell/extensions/clipboard-indicator" = {
    enable-keybindings = true;
    toggle-menu = [ "<Alt>c" ];
    open-at-cursor = true;
    show-search-bar = true;
  };
}
