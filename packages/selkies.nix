{
  lib,
  stdenv,
  fetchurl,
  appimage-run,
  makeWrapper,
}:

# Selkies als AppImage-Wrap: nicht in nixpkgs, und das AppImage bringt
# Python, pixelflux/pcmflux (Capture/Encode) und den Web-Client komplett
# mit. Vom Host erwartet es nur den Graphics-Stack (libgbm/libEGL/VA-API),
# den Wayland-Display-Server und den Session-Bus — genau die Dinge, die
# appimage-runs FHS-Environment vom System durchreicht.
#
# Betrieben wird das Ganze über den systemd-Userservice in
# modules/host/selkies.nix (attach an die echte GNOME-Wayland-Session
# via --wayland-host-display).
stdenv.mkDerivation (finalAttrs: {
  pname = "selkies";
  version = "2.2.1";

  src = fetchurl {
    url = "https://github.com/selkies-project/selkies/releases/download/${finalAttrs.version}/selkies-${finalAttrs.version}-x86_64.AppImage";
    hash = "sha256-QE3AfW0P4t6bIGRuNSSEyyK2NuCDOX/4hQkHMH0vJQ4=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # AppImage bleibt Byte-identisch — kein patchelf/strip anfassen.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm555 $src $out/share/selkies/selkies.AppImage
    # APPIMAGE_EXTRACT_AND_RUN: AppImages mounten sich sonst über FUSE —
    # im systemd-Userservice ohne fusermount-Zugriff der robuste Weg.
    makeWrapper ${lib.getExe appimage-run} $out/bin/selkies \
      --set APPIMAGE_EXTRACT_AND_RUN 1 \
      --add-flags "$out/share/selkies/selkies.AppImage"

    runHook postInstall
  '';

  meta = {
    description = "Low-Latency Web Remote Desktop & Game Streaming (HTML5/WebSocket)";
    homepage = "https://github.com/selkies-project/selkies";
    license = lib.licenses.mpl20;
    mainProgram = "selkies";
    platforms = [ "x86_64-linux" ];
  };
})
