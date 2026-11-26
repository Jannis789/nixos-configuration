#!/usr/bin/env python3
"""Native-Messaging-Host (ADR-010): liefert das agenix-Keyfile an die
kdbx-keychain-Extension. Protokoll: Chrome-NM (4-Byte-LE-Länge + UTF-8-JSON).

Liest /run/agenix/kdbx-export-key zur Laufzeit — nichts liegt im Build und
nichts im Nix-Store; die Bytes landen ausschließlich in der storage.session
der Extension (ADR-004). Ein Shot pro Aufruf: lesen, antworten, beenden.

Hinweis (NMH-Lookup Firefox): das Manifest darf KEIN allowed_origins enthalten —
Firefox 161 lehnt das Chrome-only-Feld beim Schema-Check ab und verwirft dann
das GANZE Manifest (erscheint außen als clean disconnect ohne lastError).
Deshalb liefert das Paket zwei Manifeste: Firefox ohne, Chrome mit.
"""
import base64
import json
import struct
import sys

KEYFILE = "/run/agenix/kdbx-export-key"


def read_message():
    raw_len = sys.stdin.buffer.read(4)
    if len(raw_len) != 4:
        return None
    (length,) = struct.unpack("<I", raw_len)
    return json.loads(sys.stdin.buffer.read(length).decode("utf-8"))


def send_message(obj):
    data = json.dumps(obj).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(data)) + data)
    sys.stdout.buffer.flush()


def main():
    msg = read_message()
    if msg is None:
        return
    if msg.get("type") != "getKeyfile":
        send_message({"ok": False, "error": "unbekannter Typ"})
        return
    try:
        with open(KEYFILE, "rb") as fh:
            b64 = base64.b64encode(fh.read()).decode("ascii")
        send_message({"ok": True, "b64": b64, "path": KEYFILE})
    except OSError as exc:
        send_message({"ok": False, "error": str(exc)})


if __name__ == "__main__":
    main()
