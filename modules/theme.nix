{
  pkgs,
  config,
  ...
}:
{
  stylix = {
    enable = true;
    autoEnable = false;

    base16Scheme = "${config.stylix.inputs.tinted-schemes}/base16/ayu-dark.yaml";
    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font";
      };
    };

    targets = {
      gnome = {
        enable = true;
        colors.enable = true;
        fonts.enable = true;
        polarity.enable = true;
      };

      gtk.enable = true;

      firefox = {
        enable = true;
        profileNames = [ "default" ];
        firefoxGnomeTheme.enable = true;
      };

      ghostty.enable = true;
      starship.enable = true;
    };
  };
}
