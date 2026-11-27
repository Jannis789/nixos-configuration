{
  runCommand,
  writers,
}:
# Native-Messaging-Host für kdbx-keychain (ADR-010): stellt das agenix-Keyfile
# (/run/agenix/kdbx-export-key.key) per chrome-NM-Protokoll bereit. Nichts liegt im
# Build und nichts im Nix-Store; die Bytes landen ausschließlich in der
# storage.session der Extension (ADR-004).
#
# ZWEI Manifeste (empirisch, Firefox 161): Firefox lehnt das Chrome-only-Feld
# allowed_origins beim Manifest-Schema-Check ab und verwirft dann das gesamte
# Manifest — außen sichtbar nur als clean disconnect ohne lastError. Firefox
# bekommt deshalb ein Manifest OHNE allowed_origins, Chrome eines MIT
# (Chrome adressiert Extensions über allowed_origins, nicht allowed_extensions).
# Deployment:
#   Firefox: wrapper-Option nativeMessagingHosts (hosts/jannis/home.nix)
#   Chrome:  home.file → ~/.config/google-chrome|chromium/NativeMessagingHosts/
let
  host = writers.writePython3Bin "kdbx-keychain-keyfile-host"
    {
      flakeIgnore = [
        "E265"
        "E501"
        "W291"
        "W292"
        "W293"
      ];
    }
    ./kdbx-keychain-keyfile-host/host.py;
in
runCommand "kdbx-keychain-keyfile-host"
  {
    meta.description = "Native-Messaging-Host: agenix-Keyfile für kdbx-keychain";
    passthru.manifest = "lib/mozilla/native-messaging-hosts/kdbx_keychain_keyfile.json";
    passthru.manifestChrome = "share/native-messaging-hosts/chrome/kdbx_keychain_keyfile.json";
  }
  ''
    mkdir -p $out/bin $out/lib/mozilla/native-messaging-hosts $out/share/native-messaging-hosts/chrome
    cp ${host}/bin/kdbx-keychain-keyfile-host $out/bin/

    # Firefox: KEIN allowed_origins (Schema-Ablehnung → Manifest wird verworfen)
    cat > $out/lib/mozilla/native-messaging-hosts/kdbx_keychain_keyfile.json <<JSON
{
  "name": "kdbx_keychain_keyfile",
  "description": "liefert das agenix-Keyfile an kdbx-keychain (ADR-010)",
  "path": "$out/bin/kdbx-keychain-keyfile-host",
  "type": "stdio",
  "allowed_extensions": [ "kdbx-keychain@nix-dev.link" ]
}
JSON

    # Chrome: MIT allowed_origins (Chrome braucht sie, allowed_extensions genügt nicht)
    cat > $out/share/native-messaging-hosts/chrome/kdbx_keychain_keyfile.json <<JSON
{
  "name": "kdbx_keychain_keyfile",
  "description": "liefert das agenix-Keyfile an kdbx-keychain (ADR-010)",
  "path": "$out/bin/kdbx-keychain-keyfile-host",
  "type": "stdio",
  "allowed_extensions": [ "kdbx-keychain@nix-dev.link" ],
  "allowed_origins": [ "chrome-extension://giaekmmanecjlcpifjmleemimokmeoka/" ]
}
JSON
  ''
