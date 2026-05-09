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
  validTweaks = [ "frappe" "macchiato" "black" "float" "outline" "macos" ];

  # Validierung (präzise, mit lesbaren Fehlern)
  _ = with lib;
    checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Accent" validAccents accent
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Shade" validShades [shade]
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültige Size" validSizes [size]
    (checkListOfEnum "Catppuccin-GTK-Theme: Ungültiger Tweak" validTweaks tweaks id)));

in
stdenv.mkDerivation rec {
  pname = "Catppuccin-GTK-Theme";
  version = "2025-11-05";

  src = fetchFromGitHub {
    owner = "Fausto-Korpsvart";
    repo = pname;
    rev = "f25d8cf688d8f224f0ce396689ffcf5767eb647e";
    hash = "sha256-W+NGyPnOEKoicJPwnftq26iP7jya1ZKq38lMjx/k9ss=";
  };

  nativeBuildInputs = [ jdupes sassc bash ];

  propagatedUserEnvPkgs = [ gtk-engine-murrine ];

  postPatch = ''
    patchShebangs ./themes/install.sh
    patchShebangs ./themes/gtkrc.sh
  '';
  
  installPhase = ''
    runHook preInstall
  
    mkdir -p $out/share/themes
  
    ./themes/install.sh \
      --name "${pname}" \
      ${lib.optionalString (accent != [ "default" ]) "--theme ${lib.concatStringsSep " " accent}"} \
      ${lib.optionalString (shade != null) "--color ${shade}"} \
      ${lib.optionalString (size != null) "--size ${size}"} \
      ${lib.optionalString (tweaks != [ ]) "--tweaks ${lib.concatStringsSep " " tweaks}"} \
      --dest "$out/share/themes"
  
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