{ lib, fetchFromGitHub, buildNpmPackage, glib }:

buildNpmPackage {
  pname = "hanabi-extension";
  version = "1";

  src = fetchFromGitHub {
    owner = "jeffshee";
    repo = "gnome-ext-hanabi";
    rev = "4eeb4f6e480ed38c1c013eef9c6a628f63a3dc42";
    hash = "sha256-pzbhmFiFLc0BF150xIS0S16vmsWQZYPmqPu4UcPUI5I=";
  };

  npmDepsHash = "sha256-uYhpa0MdWgkvX9XRk6lHR3ShoDtTKfrP9ZFsIxv34X8=";

  uuid = "hanabi-extension@jeffshee.github.io";
  settingsSchema = "io.github.jeffshee.hanabi-extension";

  nativeBuildInputs = [ glib ];

  installPhase = ''
    runHook preInstall
    extdir="$out/share/gnome-shell/extensions/$uuid"
    # Schemas gehören in den Extension-Ordner (nixpkgs-Konvention) — dort
    # sucht GNOME-Shell per getSettings; das System-Schemas-Verzeichnis
    # wird dafür nicht konsultiert.
    mkdir -p "$extdir/renderer" "$extdir/schemas"
    sed -e "s|@uuid@|$uuid|g" \
        -e "s|@settings_schema@|$settingsSchema|g" \
        -e "s|@version@|$version|" \
        src/metadata.json.in > metadata.json
    install -Dm644 metadata.json "$extdir/"
    install -Dm644 src/_build/extension.js src/_build/prefs.js "$extdir/"
    install -Dm644 src/_build/renderer.js "$extdir/renderer/"
    install -Dm644 src/renderer/stylesheet.css "$extdir/renderer/"
    install -Dm644 LICENSE "$extdir/"
    install -Dm644 src/schemas/$settingsSchema.gschema.xml "$extdir/schemas/"
    glib-compile-schemas "$extdir/schemas"
    runHook postInstall
  '';

  meta = {
    description = "Live Wallpaper for GNOME (Hanabi)";
    homepage = "https://github.com/jeffshee/gnome-ext-hanabi";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
