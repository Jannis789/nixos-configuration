#!/usr/bin/env python3
"""Setzt den gestreamten Monitor auf die Auflösung des Moonlight-Clients.

Hintergrund: GNOME/mutter kann Auflösungen nicht frei erfinden — es
akzeptiert nur Modi, die der Monitor anbietet. Der Acer XZ342CU bietet sie
zum Glück reichlich (720p … 3440x1440@165, 4K). "Adaptive Auflösung" heißt
hier deshalb: beim Stream-Start den Modus wählen, der der Client-Auflösung
am nächsten kommt, und beim Trennen exakt das vorherige Layout
zurückspielen.

Aufgerufen wird das aus Sunshines global_prep_cmd; die Client-Daten kommen
über SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS (src/process.cpp legt sie in die
Umgebung der prep-Commands).

Steuerung ausschließlich über org.gnome.Mutter.DisplayConfig:
  * GetCurrentState     → Monitore, Modi, aktuelles Layout
  * ApplyMonitorsConfig → Layout setzen (method=1 = nur temporär, schreibt
                          monitors.xml NICHT um)

Falle: GetCurrentState meldet in mutter >= 47 JE LOGISCHEM MONITOR nur
(connector, vendor, product, serial) — der gerade aktive Modus fehlt dort.
Den Schreibtisch-Sollzustand bekommt das Skript deshalb als "Profil" von
außen (siehe modules/host/sunshine.nix):  "DP-3=3440x1440@165,HDMI-1=..."
"""

from __future__ import annotations

import ast
import json
import os
import re
import subprocess
import sys
import time

DEST = "org.gnome.Mutter.DisplayConfig"
OBJ = "/org/gnome/Mutter/DisplayConfig"
IFACE = "org.gnome.Mutter.DisplayConfig"

STATE_PATH = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR") or "/tmp", "sunshine-display-mode.json"
)

TYPES_RE = re.compile(
    r"@a\(ssa\{sv\}\)|@a\{sv\}|\b(?:u?int(?:16|32|64)|byte|double)\s+"
)


def log(message: str) -> None:
    print(f"[display-mode] {message}", file=sys.stderr, flush=True)


def gdbus(method: str, *args: str) -> str:
    command = [
        "gdbus",
        "call",
        "--session",
        "--dest",
        DEST,
        "--object-path",
        OBJ,
        "--method",
        f"{IFACE}.{method}",
        *args,
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"{method}: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def to_python(text: str):
    text = TYPES_RE.sub("", text)
    text = re.sub(r"<([^<>]*)>", r"\1", text)
    text = re.sub(r"\btrue\b", "True", text)
    text = re.sub(r"\bfalse\b", "False", text)
    text = re.sub(r"\bnothing\b", "None", text)
    return ast.literal_eval(text)


def dbl(value: float) -> str:
    """Double-Literal, das GVariant sicher als 'd' akzeptiert (1.0, nicht 1)."""
    text = f"{value:.4f}".rstrip("0")
    return text + "0" if text.endswith(".") else text


# ---------------------------------------------------------------- Zustand lesen
def get_state():
    state = to_python(gdbus("GetCurrentState"))
    serial = int(state[0])

    connectors: dict[str, list[dict]] = {}
    for entry in state[1]:
        connector = entry[0][0]
        modes = [
            {
                "id": mode[0],
                "w": int(mode[1]),
                "h": int(mode[2]),
                "rate": float(mode[3]),
                "scales": [float(scale) for scale in mode[5]],
                "props": mode[6],
            }
            for mode in entry[1]
        ]
        connectors[connector] = modes

    # logical_monitors: a(iiduba(ssss)a{sv}) — Monitor-Identität, KEIN Modus.
    # Der Property-Dict am Ende ist reine Lese-Metadaten und wird von
    # ApplyMonitorsConfig (a(iiduba(ssa{sv}))) nicht angenommen.
    layout = [
        {
            "x": int(x),
            "y": int(y),
            "scale": float(scale),
            "transform": int(transform),
            "primary": bool(primary),
            "connector": monitors[0][0],
        }
        for x, y, scale, transform, primary, monitors, _props in state[2]
    ]
    return serial, connectors, layout


# ------------------------------------------------------------- Modi auswählen
def pick_scale(mode) -> float:
    if 1.0 in mode["scales"]:
        return 1.0
    return min(mode["scales"], key=lambda value: abs(value - 1.0)) if mode["scales"] else 1.0


def parse_profile(profile: str | None) -> dict[str, str]:
    """'DP-3=3440x1440@165,HDMI-1=2560x1440@144' → {connector: modus-id-artig}"""
    specs: dict[str, str] = {}
    for chunk in (profile or "").split(","):
        chunk = chunk.strip()
        if not chunk or "=" not in chunk:
            continue
        connector, spec = chunk.split("=", 1)
        specs[connector.strip()] = spec.strip()
    return specs


def find_mode(modes, spec: str | None):
    """Modus zu '3440x1440@165' bzw. exakter Modus-ID suchen."""
    if not spec:
        return None
    exact = next((mode for mode in modes if mode["id"] == spec), None)
    if exact:
        return exact
    match = re.fullmatch(r"(\d+)x(\d+)(?:@([\d.]+))?", spec)
    if not match:
        return None
    width, height = int(match.group(1)), int(match.group(2))
    rate = float(match.group(3)) if match.group(3) else None
    candidates = [
        mode
        for mode in modes
        if mode["w"] == width and mode["h"] == height and "+vrr" not in mode["id"]
    ]
    if not candidates:
        return None
    if rate is None:
        return sorted(candidates, key=lambda mode: mode["rate"])[-1]
    return min(candidates, key=lambda mode: abs(mode["rate"] - rate))


def preferred_mode(modes):
    """EDID-Vorzug (is-preferred), sonst größter Modus mit höchster Rate."""
    marked = [
        mode
        for mode in modes
        if "+vrr" not in mode["id"] and mode["props"].get("is-preferred")
    ]
    pool = marked or [mode for mode in modes if "+vrr" not in mode["id"]] or modes
    return sorted(pool, key=lambda mode: (mode["w"] * mode["h"], mode["rate"]))[-1]


def pick_client_mode(modes, width: int, height: int, fps: float):
    plain = [mode for mode in modes if "+vrr" not in mode["id"]] or modes
    candidates = [mode for mode in plain if mode["w"] == width and mode["h"] == height]

    if not candidates:
        groups: dict[tuple[int, int], list[dict]] = {}
        for mode in plain:
            groups.setdefault((mode["w"], mode["h"]), []).append(mode)

        target_ar = width / height
        best = min(groups, key=lambda res: abs(res[0] / res[1] - target_ar) / target_ar)
        if abs(best[0] / best[1] - target_ar) / target_ar > 0.02:
            target_area = width * height
            ordered = sorted(groups, key=lambda res: res[0] * res[1])
            best = next(
                (res for res in ordered if res[0] * res[1] >= target_area),
                ordered[-1],
            )
        candidates = groups[best]

    def rate_distance(mode) -> tuple[int, float]:
        delta = mode["rate"] - fps
        # Treffer im ±1-Hz-Fenster bevorzugen (59.94 vs. 60 usw.).
        return (0 if abs(delta) <= 1.0 else 1, abs(delta))

    return sorted(candidates, key=rate_distance)[0]


# ------------------------------------------------------------------ Layout I/O
def fmt_layout(layout) -> str:
    logical = []
    for entry in layout:
        monitors = ", ".join(
            f"('{connector}', '{mode_id}', {{}})"
            for connector, mode_id in entry["monitors"]
        )
        logical.append(
            f"({entry['x']}, {entry['y']}, {dbl(entry['scale'])}, "
            f"{entry['transform']}, {'true' if entry['primary'] else 'false'}, "
            f"[{monitors}])"
        )
    return "[" + ", ".join(logical) + "]"


def apply_layout(layout) -> None:
    serial, _, _ = get_state()
    gdbus("ApplyMonitorsConfig", str(serial), "1", fmt_layout(layout), "{}")


def connector_of(entry) -> str:
    return entry.get("connector") or entry["monitors"][0][0]


def layout_signature(layout) -> list[tuple]:
    return sorted(
        (
            connector_of(entry),
            entry["x"],
            entry["y"],
            round(entry["scale"], 3),
            entry["transform"],
            entry["primary"],
        )
        for entry in layout
    )


def wait_until_applied(expected, timeout: float = 2.0) -> None:
    """Wartet, bis der Compositor das Layout wirklich übernommen hat.

    ApplyMonitorsConfig kehrt zurück, bevor der KMS-Moduswechsel gelandet ist.
    Sunshine liest die Framebuffer-Größe unmittelbar danach — ohne dieses
    Warten startet die KMS-Capture noch mit der alten Auflösung (Log:
    "Mismatch on expected Resolution compared to actual resolution").
    """
    signature = layout_signature(expected)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            _, _, current = get_state()
        except RuntimeError:
            break
        if layout_signature(current) == signature:
            time.sleep(0.25)  # Moduswechsel im KMS-Thread auslaufen lassen
            return
        time.sleep(0.05)
    log("Warnung: Layout nach 2 s noch nicht übernommen")


def resolve_layout(connectors, layout, profile: dict[str, str]) -> list[dict]:
    """Aktuelles Layout mit expliziten Modus-IDs (Sollzustand des Desktops)."""
    resolved = []
    for entry in layout:
        connector = entry["connector"]
        modes = connectors.get(connector) or []
        mode = (
            find_mode(modes, profile.get(connector))
            or preferred_mode(modes)
            if modes
            else None
        )
        if mode is None:
            log(f"{connector}: keine Modi gemeldet — wird ausgelassen")
            continue
        resolved.append(
            {
                "x": entry["x"],
                "y": entry["y"],
                "scale": pick_scale(mode),
                "transform": entry["transform"],
                "primary": entry["primary"],
                "monitors": [(connector, mode["id"])],
            }
        )
    return resolved


def streaming_layout(connectors, resolved, target, mode, scale) -> list[dict]:
    """Nur den Ziel-Monitor aktiv lassen, alle anderen ausblenden.

    Sunshines KMS-Capture greift sich das erste aktive CRTC — sind zwei
    Monitore aktiv, ist das nicht zwingend der gewünschte (im Log stand
    "Mapped 'HDMI-A-1' to kmsgrab monitor index 0", also der 27"-Portrait-
    Monitor). Mit genau einem aktiven Monitor ist die Capture eindeutig:
    richtige Auflösung, richtige Ausrichtung, keine Fenster auf einem
    unsichtbaren Schirm, und der Desktop ist exakt so groß wie der Client.
    """
    target_connector = target["monitors"][0][0]
    return [
        {
            "x": 0,
            "y": 0,
            "scale": scale,
            "transform": target["transform"],
            "primary": True,
            "monitors": [(target_connector, mode["id"])],
        }
    ]


# -------------------------------------------------------------------- Befehle
def cmd_apply(profile_arg: str | None = None) -> int:
    width = int(os.environ.get("SUNSHINE_CLIENT_WIDTH") or 0)
    height = int(os.environ.get("SUNSHINE_CLIENT_HEIGHT") or 0)
    fps = float(os.environ.get("SUNSHINE_CLIENT_FPS") or 60)

    if not (width and height):
        log("keine Client-Auflösung in der Umgebung — nichts zu tun")
        return 0

    profile = parse_profile(profile_arg or os.environ.get("SUNSHINE_DISPLAY_PROFILE"))
    _, connectors, layout = get_state()
    if not layout:
        log("kein aktives Monitor-Layout — nichts zu tun")
        return 0

    resolved = resolve_layout(connectors, layout, profile)
    if not resolved:
        return 1

    target = next((entry for entry in resolved if entry["primary"]), resolved[0])
    connector = target["monitors"][0][0]
    modes = connectors.get(connector) or []
    if not modes:
        log(f"keine Modi für {connector} — nichts zu tun")
        return 0

    mode = pick_client_mode(modes, width, height, fps)
    scale = pick_scale(mode)

    # Sollzustand des Schreibtischs nur beim ersten Apply sichern — aber nur,
    # wenn der gespeicherte Zustand noch zum aktuellen Layout passt. Sonst hat
    # ein abgebrochener Stream (Undo fehlgeschlagen) den Streaming-Zustand als
    # "Desktop" hinterlassen und würde beim nächsten Restore stehen bleiben.
    stale = False
    if os.path.exists(STATE_PATH):
        try:
            with open(STATE_PATH, encoding="utf-8") as handle:
                saved = json.load(handle)
            stale = layout_signature(saved["layout"]) != layout_signature(layout)
        except (OSError, ValueError, KeyError):
            stale = True
    if stale:
        log("gespeicherter Zustand passt nicht zum Desktop — wird überschrieben")
    if not os.path.exists(STATE_PATH) or stale:
        with open(STATE_PATH, "w", encoding="utf-8") as handle:
            json.dump({"layout": resolved, "connector": connector}, handle)

    new_layout = streaming_layout(connectors, resolved, target, mode, scale)
    apply_layout(new_layout)
    wait_until_applied(new_layout)
    log(
        f"Client {width}x{height}@{fps:g} → {connector} {mode['id']} "
        f"(scale {scale:g}); Desktop wird beim Trennen zurückgesetzt"
    )
    return 0


def cmd_restore() -> int:
    if not os.path.exists(STATE_PATH):
        log("kein gespeicherter Zustand — nichts zurückzusetzen")
        return 0

    with open(STATE_PATH, encoding="utf-8") as handle:
        state = json.load(handle)

    try:
        apply_layout(state["layout"])
        wait_until_applied(state["layout"])
    except (RuntimeError, KeyError) as error:
        log(f"Restore fehlgeschlagen ({error}) — setze bevorzugten Modus")
        return cmd_reset(state.get("connector"), None)

    os.unlink(STATE_PATH)  # erst nach erfolgreichem Zurücksetzen wegwerfen
    log("Desktop-Layout wiederhergestellt")
    return 0


def cmd_reset(connector: str | None = None, profile_arg: str | None = None) -> int:
    profile = parse_profile(profile_arg or os.environ.get("SUNSHINE_DISPLAY_PROFILE"))
    _, connectors, layout = get_state()
    if not layout:
        log("kein aktives Monitor-Layout")
        return 0

    resolved = resolve_layout(connectors, layout, profile)
    if not resolved:
        return 1

    if connector:
        # Einzelnen Monitor auf Profil-/Vorzug-Modus zurücksetzen; alle
        # anderen Monitore bleiben (bzw. werden wieder) aktiv.
        for entry in resolved:
            if entry["monitors"][0][0] == connector:
                mode = find_mode(connectors[connector], entry["monitors"][0][1])
                apply_layout(resolved)
                log(f"{connector} zurück auf {mode['id']}")
                return 0
        log(f"{connector} ist derzeit nicht aktiv")
        return 1

    apply_layout(resolved)
    log("Desktop-Layout aus Profil wiederhergestellt")
    return 0


def cmd_show() -> int:
    _, connectors, layout = get_state()
    for entry in layout:
        connector = entry["connector"]
        marker = "*" if entry["primary"] else " "
        print(
            f"{marker} {connector:10s} pos=({entry['x']},{entry['y']}) "
            f"scale={entry['scale']:g} rotate={entry['transform']} "
            f"({len(connectors.get(connector, []))} Modi, "
            f"Vorzug: {preferred_mode(connectors[connector])['id']})"
        )
    return 0


def main(argv: list[str]) -> int:
    command = argv[1] if len(argv) > 1 else "apply"
    argument = argv[2] if len(argv) > 2 else None
    try:
        if command == "apply":
            return cmd_apply(argument)
        if command == "restore":
            return cmd_restore()
        if command == "reset":
            return cmd_reset(argument, argv[3] if len(argv) > 3 else None)
        if command == "show":
            return cmd_show()
    except RuntimeError as error:
        log(str(error))
        return 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
