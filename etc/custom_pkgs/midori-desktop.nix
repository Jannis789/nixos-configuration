{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  gtk3,
  alsa-lib,
  libX11,
  libXext,
  libXrandr,
  libXcomposite,
  libXdamage,
  libXfixes,
  libXrender,
  libxcb,
  dbus-glib,
  pango,
  atk,
  cairo,
  gdk-pixbuf,
  adwaita-icon-theme,
  libglvnd,
}:

let
  version = "11.7.2";
  runtimeLibs = [
    stdenv.cc.cc.lib
    alsa-lib
    gtk3
    libX11
    libXext
    libXrandr
    libXcomposite
    libXdamage
    libXfixes
    libXrender
    libxcb
    dbus-glib
    pango
    atk
    cairo
    gdk-pixbuf
    libglvnd
  ];
in
stdenv.mkDerivation {
  pname = "midori-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/goastian/midori-desktop/releases/download/v${version}/midori-${version}.linux-x86_64.tar.xz";
    hash = "sha256-I2N5YacYi/xd/223eipGkBamZza4usr4L6F78VWsENg=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = runtimeLibs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/midori
    cp -r midori/* $out/lib/midori/

    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/lib/midori/midori
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/lib/midori/midori-bin
    for f in $out/lib/midori/crashhelper $out/lib/midori/glxtest $out/lib/midori/vaapitest $out/lib/midori/pingsender $out/lib/midori/updater; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$f" 2>/dev/null || true
    done

    mkdir -p $out/bin
    makeWrapper $out/lib/midori/midori $out/bin/midori \
      --prefix LD_LIBRARY_PATH : "$out/lib/midori:${lib.makeLibraryPath runtimeLibs}" \
      --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share" \
      --set MOZ_ENABLE_WAYLAND 1 \
      --set MOZ_APP_LAUNCHER midori \
      --set MOZ_LEGACY_PROFILES 1

    for size in 16 32 48 64 128; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      cp midori/browser/chrome/icons/default/default''${size}.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/midori.png
    done

    mkdir -p $out/share/applications
    cat > $out/share/applications/midori.desktop <<EOF
    [Desktop Entry]
    Version=1.0
    Name=Midori
    Comment=Browse the World Wide Web
    GenericName=Web Browser
    Exec=midori %u
    Icon=midori
    Type=Application
    Categories=Network;WebBrowser;
    MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
    StartupNotify=true
    StartupWMClass=Midori
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Lightweight web browser (Floorp/Firefox fork)";
    homepage = "https://github.com/goastian/midori-desktop";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "midori";
  };
}
