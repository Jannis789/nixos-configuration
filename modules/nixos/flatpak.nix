{
  config,
  pkgs,
  lib,
  ...
}:

let
  r = config.theme._resolved;
  isRewaita = config.theme.gtk.name == "rewaita";
in
{
  services = {
    flatpak = {
      enable = true;
      update.onActivation = true;

      packages = [
        {
          appId = "net.lutris.Lutris";
          origin = "flathub";
        }
        {
          appId = "com.usebottles.bottles";
          origin = "flathub";
        }
        {
          appId = "com.github.tchx84.Flatseal";
          origin = "flathub";
        }
        {
          appId = "io.github.kolunmi.Bazaar";
          origin = "flathub";
        }
        {
          appId = "app.xmcl.voxelum";
          origin = "flathub";
        }
        {
          appId = "io.github.tobagin.karere";
          origin = "flathub";
        }
      ];

      overrides = {
        global = {
          Context.filesystems = [
            "/nix/store:ro"
            "xdg-config/fontconfig:ro"
            "xdg-config/gtk-3.0:ro"
            "xdg-config/gtk-4.0:ro"
            "xdg-data/themes:ro"
            "xdg-data/icons:ro"
            "~/.local/share/themes:ro"
            "~/.local/share/icons:ro"
          ];
          Environment.GTK_THEME = lib.mkIf (!isRewaita) (if r.gtkThemeName != "" then r.gtkThemeName else "Adwaita");
          Environment.XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
        };
      };
    };

    dbus.enable = true;
  };
}
