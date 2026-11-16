{ ... }:
{
  dconf.settings."org/gnome/shell" = {
    disabled-extensions = [ "hanabi-extension@jeffshee.github.io" ];

    enabled-extensions = [
      "color-picker@tuberry"
      "blur-my-shell@aunetx"
      "caffeine@patapon.info"
      "monitor@astraext.github.io"
      "dash-to-dock@micxgx.gmail.com"
      "clipboard-indicator@tudmotu.com"
      "window-calls@domandoman.xyz"
      "ocr-to-clipboard@oreocapybara"
    ];
  };

  dconf.settings."org/gnome/shell/keybindings" = {
    show-screenshot-ui = [
      "<Print>"
      "<Control><Shift>s"
    ];
  };

  dconf.settings."org/gnome/shell/extensions/ocr-to-clipboard" = {
    capture-ocr-shortcut = [ "<Control><Shift>x" ];
  };

  dconf.settings."org/gnome/shell/extensions/dash-to-dock" = {
    running-indicator-style = "METRO";
    background-opacity = 0.2;
    transparency-mode = "FIXED";
    dock-position = "LEFT";
    custom-theme-shrink = true;
    extend-height = true;
    dock-fixed = true;
    show-apps-at-top = false;
  };

  dconf.settings."org/gnome/shell/extensions/blur-my-shell/panel" = {
    sigma = 20;
    static-blur = false;
  };

  dconf.settings."org/gnome/shell/extensions/blur-my-shell/popup" = {
    blur = false;
  };

  dconf.settings."org/gnome/shell/extensions/clipboard-indicator" = {
    enable-keybindings = true;
    toggle-menu = [ "<Super>v" ];
    open-at-cursor = true;
    show-search-bar = true;
  };
}
