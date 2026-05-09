{ lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  adwaita-icon-theme,
  gnome-icon-theme,
  hicolor-icon-theme,
}:

stdenvNoCC.mkDerivation rec {
  pname = "Hatter";
  version = "2025-11-17";

  src = fetchFromGitHub {
    owner = "Mibea";
    repo = "Hatter";
    rev = "0b4dfa4f577ec2514562c56419386deda53c26da";
    hash = "sha256-K9T1L0nwJSCL+9ybGqcdRxQvFb/H84gYVLRQysqJyYQ=";
  };

  nativeBuildInputs = [ gtk3 ];

  propagatedBuildInputs = [
    adwaita-icon-theme
    gnome-icon-theme
    hicolor-icon-theme
  ];

  dontDropIconThemeCache = true;
  dontRewriteSymlinks = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    # Unterordner nach Name des Themes
    THEME_DIR="$out/share/icons/${pname}"
    mkdir -p "$THEME_DIR"

    # Alles aus src/ kopieren
    cp -a src/* "$THEME_DIR"/

    # Optional: interne Duplikate entfernen
    jdupes -l -r "$THEME_DIR" || true

    # Icon-Cache generieren
    gtk-update-icon-cache "$THEME_DIR"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Hatter Icon Theme";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    homepage = "https://github.com/Mibea/Hatter";
  };
}
