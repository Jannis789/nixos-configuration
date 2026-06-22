{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  makeDesktopItem,
  glib,
  nspr,
  nss,
  atk,
  at-spi2-core,
  dbus,
  cups,
  expat,
  libxcb,
  libxkbcommon,
  alsa-lib,
  libdrm,
  libgbm,
  libX11,
  libXext,
  cairo,
  pango,
  udev,
  libXcomposite,
  libXdamage,
  libXfixes,
  libXrandr,
  gtk3,
  adwaita-icon-theme,
  libglvnd,
}:

let
  version = "0.13.4.1";
  runtimeLibs = [
    glib
    nspr
    nss
    atk
    at-spi2-core
    dbus
    cups
    expat
    libxcb
    libxkbcommon
    alsa-lib
    libgbm
    libX11
    libXext
    cairo
    pango
    udev
    libXcomposite
    libXdamage
    libXfixes
    libXrandr
    gtk3
    libglvnd
  ];
in
stdenv.mkDerivation {
  pname = "helium";
  inherit version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    hash = "sha256-rt//wcAnH7n1ol/PfP37axHpIUKrWXSQN6SisGtE7hw=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = runtimeLibs;

  desktopItem = makeDesktopItem {
    name = "helium";
    exec = "helium %U";
    icon = "helium";
    desktopName = "Helium";
    genericName = "Web Browser";
    comment = "Access the Internet";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    startupWMClass = "helium";
    actions = {
      new-window = {
        name = "New Window";
        exec = "helium";
      };
      new-private-window = {
        name = "New Incognito Window";
        exec = "helium --incognito";
      };
    };
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/helium
    cp -r helium-${version}-x86_64_linux/* $out/lib/helium/

    for f in $out/lib/helium/helium $out/lib/helium/helium_crashpad_handler $out/lib/helium/chromedriver; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$f" 2>/dev/null || true
    done

    mkdir -p $out/bin
    makeWrapper $out/lib/helium/helium-wrapper $out/bin/helium \
      --prefix LD_LIBRARY_PATH : "$out/lib/helium:${lib.makeLibraryPath runtimeLibs}" \
      --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share" \
      --set CHROME_VERSION_EXTRA "nixos" \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--force-device-scale-factor=1.2"

    for res in 256; do
      mkdir -p $out/share/icons/hicolor/''${res}x''${res}/apps
      cp $out/lib/helium/product_logo_''${res}.png \
        $out/share/icons/hicolor/''${res}x''${res}/apps/helium.png
    done

    install -m 644 -D -t $out/share/applications $desktopItem/share/applications/*

    runHook postInstall
  '';

  meta = {
    description = "Chromium-based web browser";
    homepage = "https://github.com/nicehash/helium";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
