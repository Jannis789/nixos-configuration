{
  config,
  lib,
  osConfig,
  ...
}:

let
  r = osConfig.theme._resolved;
in
{
  config.gtk = lib.mkIf (osConfig.theme.icons.name != "none") {
    iconTheme = {
      name = r.iconName;
      package = r.iconPkg;
    };
  };
}
