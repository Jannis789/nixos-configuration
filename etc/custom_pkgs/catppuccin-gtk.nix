{ lib
, stdenv
, fetchFromGitHub
, gtk-engine-murrine
, jdupes
, sassc
, bash
, accent ? [ "default" ]
, shade ? "dark"
, size ? "standard"
, tweaks ? [ ]
}:

let
  validAccents = [
    "default"
    "blue"
    "flamingo"
    "green"
    "grey"
    "lavender"
    "maroon"
    "mauve"
    "peach"
    "pink"
    "red"
    "rosewater"
    "sapphire"
    "sky"
    "teal"
    "yellow"
    "all"
  ];

  validShades = [ "light" "dark" ];
  validSizes = [ "standard" "compact" ];
  # Abgleich mit upstream themes/lib/tweaks.sh (commit 35695ce, "feat!").
  #   * "outline" wurde ersatzlos gestrichen
  #   * "black" ist jetzt die User-Alias-Bezeichnung fuer "blackness"
  validTweaks = [ "frappe" "macchiato" "black" "blackness" "float" "macos" ];

  # Validierung (präzise, mit lesbaren Fehlern)
  _ = with lib;
    checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Accent" validAccents accent
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Shade" validShades [shade]
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültige Size" validSizes [size]
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Tweak" validTweaks tweaks id)));

in
stdenv.mkDerivation rec {
  pname = "Catppuccin-GTK-Theme";
  version = "2026-06-17";

  src = fetchFromGitHub {
    owner = "Fausto-Korpsvart";
    repo = pname;
    rev = "35695ce73854ec59342a34abe7ef0684be1138dd";
    hash = "sha256-kBVpS6SSwEcHDrgUJx8Xh2spuIIM6T2K91IogYrIMWs=";
  };

  nativeBuildInputs = [ jdupes sassc bash ];

  propagatedUserEnvPkgs = [ gtk-engine-murrine ];

  postPatch = ''
    # Upstream modularisierte die Installer-Skripte (commit 35695ce, "feat!").
    # gtkrc.sh ist nach ./themes/lib/ umgezogen; die lib/ enthält jetzt zusätzliche
    # Quellmodule (parser.sh, config.sh, tweaks.sh, ...). Shebangs einmal auf das
    # ganze themes/-Verzeichnis patchen statt Datei für Datei.
    patchShebangs ./themes
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/themes

    # Upstream install.sh (commit 35695ce) sourcet Module aus $LIB_DIR. Pfad-
    # Auflösung ist $0-/CWD-relativ; pushd stellt sicher dass beide Varianten
    # funktionieren, ohne uns auf die interne Implementierung festzulegen.
    pushd themes
    ./install.sh \
      --name "${pname}" \
      ${lib.optionalString (accent != [ "default" ]) "--theme ${lib.concatStringsSep " " accent}"} \
      ${lib.optionalString (shade != null) "--color ${shade}"} \
      ${lib.optionalString (size != null) "--size ${size}"} \
      ${lib.optionalString (tweaks != [ ]) "--tweaks ${lib.concatStringsSep " " tweaks}"} \
      --dest "$out/share/themes"
    popd

    jdupes -q -L -r "$out/share"
    runHook postInstall
  '';

  meta = with lib; {
    description = "A GTK theme based on the colours of Catppuccin Community great theme: Catppuccin for Neovim the VinceLiuice's Awesome GTK Themes and the creativity of Gusbemacbe's: Suru Plus Icon Theme.";
    homepage = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ icy-thought ];
    platforms = platforms.linux;
    mainProgram = "install.sh";
  };
}