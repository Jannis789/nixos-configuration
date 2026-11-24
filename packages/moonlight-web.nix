{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
}:

# Moonlight-Web-Stream: Browser-Client für einen Sunshine-Host.
#
# Kein Neubau nötig — upstream veröffentlicht fertige Release-Tarballs
# (Rust-Backend `web-server` + WASM/JS-Frontend in `static/`). Der Build ist
# reines Auspacken; das Binary linkt nur gegen libc/libgcc (kein OpenSSL,
# TLS macht der nginx), läuft auf NixOS also ohne patchelf.
#
# Wichtig: `static/` wird vom Server RELATIV ZUM ARBEITSVERZEICHNIS geladen
# (actix_files: "Specified path is not a directory: static"). Deshalb setzt
# der systemd-Service WorkingDirectory auf das Datenverzeichnis und legt
# dort per tmpfiles einen Symlink auf ${pname}/lib/moonlight-web/static —
# der Store bleibt read-only, DB/Config liegen daneben im State-Dir.
stdenv.mkDerivation (finalAttrs: {
  pname = "moonlight-web-stream";
  version = "3.0.2";

  src = fetchurl {
    url = "https://github.com/MrCreativ3001/moonlight-web-stream/releases/download/v${finalAttrs.version}/moonlight-web-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-S23lwcNVU+nTW9Z6M0Pr0B9n0KQhYRbAm3ixKtzMA98=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  # Fertig gebautes Binary: nicht anfassen (strip/patchelf würden es nur
  # kaputtmachen).
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/moonlight-web
    cp -r static $out/lib/moonlight-web/static
    # Im Tarball fehlt das Executable-Bit.
    install -Dm755 web-server $out/lib/moonlight-web/web-server

    # Bequemer Einstieg von der Kommandozeile (Debug/„config generate").
    makeWrapper $out/lib/moonlight-web/web-server $out/bin/moonlight-web \
      --run "cd $out/lib/moonlight-web"

    runHook postInstall
  '';

  meta = {
    description = "Moonlight/Sunshine client that streams into a web browser (WebRTC)";
    homepage = "https://github.com/MrCreativ3001/moonlight-web-stream";
    license = lib.licenses.gpl3Only;
    mainProgram = "moonlight-web";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
