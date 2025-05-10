# pkgs/flatpak.nix

{ config, pkgs, ... }:

{
  services.flatpak = {
    enable = true;
    overrides = {
      global = {
        Context.filesystems = [
          "home"
        ];
        Environment = {
          GTK_THEME = "Catppuccin-Dark";
        };
      };
    };
    packages = [
      { appId = "re.sonny.Workbench"; origin = "flathub";  }
      { appId = "com.github.tchx84.Flatseal"; origin = "flathub";  }
      { appId = "org.gnome.Builder"; origin = "flathub";  }
    ];
  };
}
