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
  config = lib.mkIf (osConfig.theme.cursor.name != "none") {
    home.sessionVariables.XCURSOR_THEME = r.cursorName;
    gtk.cursorTheme = {
      name = r.cursorName;
      package = null;
    };
  };
}
