{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.activation.installScripts = lib.hm.dag.entryAfter [ "installPackages" ] ''
    cd /tmp

    ${pkgs.git}/bin/git clone https://github.com/tkashkin/Adwaita-for-Steam 

    cd "Adwaita-for-Steam"
    ${pkgs.python3}/bin/python3 ./install.py \
      -c catppuccin-mocha

    rm -rf /tmp/Adwaita-for-Steam
  '';
}
