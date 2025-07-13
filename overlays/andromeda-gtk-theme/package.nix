{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk-engine-murrine,
}:

stdenvNoCC.mkDerivation {
  pname = "andromeda-gtk-theme";
  version = "0-unstable-2025-07-05";

  src = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Andromeda-gtk";
    rev = "4dfd5433c71975ff15f032d43f4bce557409855e";
    hash = "sha256-YzmNo7WZjF/BLKgT2wJXk0ms8bb5AydFcfPzFmRrhkU=";
    name = "Andromeda";
  };

  sourceRoot = ".";

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes
    cp -a Andromeda* $out/share/themes

    # remove uneeded files, which are not distributed in https://www.gnome-look.org/p/2039961/
    rm -rf $out/share/themes/*/.gitignore
    rm -rf $out/share/themes/*/Art
    rm -rf $out/share/themes/*/LICENSE
    rm -rf $out/share/themes/*/README.md
    rm -rf $out/share/themes/*/{package.json,package-lock.json,Gulpfile.js}
    rm -rf $out/share/themes/*/src
    rm -rf $out/share/themes/*/cinnamon/*.scss
    rm -rf $out/share/themes/*/gnome-shell/{earlier-versions,extensions,*.scss}
    rm -rf $out/share/themes/*/gtk-2.0/{assets.svg,assets.txt,links.fish,render-assets.sh}
    rm -rf $out/share/themes/*/gtk-3.0/{apps,widgets,*.scss}
    rm -rf $out/share/themes/*/gtk-4.0/{apps,widgets,*.scss}
    rm -rf $out/share/themes/*/xfwm4/{assets,render_assets.fish}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Elegant dark theme for gnome, mate, budgie, cinnamon, xfce";
    homepage = "https://github.com/EliverLara/Andromeda-gtk";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [];
  };
}
