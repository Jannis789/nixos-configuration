---
name: betterwright-driver
description: Browser-Aufgaben mit EINEM einzigen Tool-Call erledigen — via der nativ verdrahteten Pi-Extension (extensions.browser) oder betterwright exec mit Live View + Chat. Immer lesen, wenn eine Browser-Aufgabe ansteht (Login, Formulare, Buchungen, Käufe, Webseiten lesen) oder der User "Browser", "Live View", "Chat", "Handoff" oder "betterwright" erwähnt.
---

# BetterWright — Browser in einem Tool-Call

**Ziel: Eine Browser-Aufgabe = EIN Tool-Call.** Nicht Schritt für Schritt
durchklicken. In pi ist die betterwright-Extension über das pi-Manifest
verdrahtet (Package `npm:betterwright`, deklarativ in pi.nix) — die Tools
`browser`, `browser_login`, `browser_evidence`, `browser_download`
sind als `extensions.browser` etc. registriert.

## Primärer Weg (in pi): extensions.browser

**EIN Tool-Call** — der komplette Playwright-Code als `code`-Parameter,
eine `note` als Statuszeile. Der Call öffnet/lädt/liest und gibt das
Ergebnis zurück; der Browser ist persistent zwischen Calls.

```ts
await tools.call({ ref: 'extensions.browser', args: {
  code: `await page.goto('https://example.com');
        const title = await page.title();
        const h1 = await page.locator('h1').first().innerText();
        return { title, h1 };`,
  note: 'Opening example.com and reading title and h1'
}});
// → { ok: true, result: { title: "Example Domain", h1: "Example Domain" }, pages: [...], artifacts: [...] }
```

Verfügbare Globals im `code`: `page` (aktive Seite), `pages`, `context`,
`state`, `openPage`, `closePage`, `snapshot`, `screenshot`,
`artifactPath`, `dialogs`, `credentials`, `captcha`, `human`,
`overlays`, `controls`, `media`.

- Snapshots: `snapshot({interactive:true})` → `[ref=eN]`-Locators →
  `page.locator('aria-ref=eN')`. `snapshot({diff:true})` verifiziert
  eine Aktion, `screenshot({annotate:true})` zeichnet Ref-Boxen.
- Login: `browser_login` (Secrets bleiben im Worker, nie im Prompt).
  Vor Login/Signup/Checkout: `$NODE $BW skills show credential-manager`.
- CAPTCHA: `captcha.solve()` zuerst (lokal); bei `processing` Vision-
  Artifact nutzen, dann erneut. Höchstens 3 Stages, sonst Human-Handoff.
- Beweis: `browser_evidence` initialisieren/proven/auditieren; Proof-
  Screenshots vor `screenshot({kind:'proof'})` prüfen.

## Live View / Zuschauen (exec-Konsole)

Will der User live zuschauen oder während der Arbeit im Chat lenken, läuft
die interaktive Konsole mit `--live-view`. **Wichtig: Konsole und
Pi-Extension können sich NICHT gleichzeitig die persistente Profile
teilen** — wer läuft, hat den Browser; der andere bekommt eine temporäre
Profile ohne Logins. Also entweder Konsole (Zuschauen) ODER Extension
(Arbeiten), nie beides parallel.

```bash
NODE=/nix/store/5q3w8mmkmmj73xy81yx214l9r86ss9s0-nodejs-24.18.0-source/bin/node
BW=/home/jannis/.pi/agent/npm/node_modules/.bin/betterwright
export NOUS_API_KEY='<Key aus secrets.nix>'   # ist als Session-Var schon gesetzt
$NODE $BW --base-url https://inference-api.nousresearch.com/v1 \
  --api-key-env NOUS_API_KEY --model anthropic/claude-opus-5-fast \
  --live-view --host 127.0.0.1 --port 43179
# → ▶ Watch live: http://127.0.0.1:43179/?t=<token>
# User-Tunnel: ssh -L 43179:127.0.0.1:43179 jannis@192.168.178.20
```

Der Chat im Live-View **steuert den laufenden Agenten** (nächster Turn),
er startet keinen Task. Neue Tasks über die Konsole (FIFO) oder als
Folge-`exec`.

## Verifizierte Fakten (getestet 2026-08-26)

- Modell-Backend: Nous-Inference-Endpoint proxyt OpenRouter-IDs.
  `anthropic/claude-opus-5-fast` läuft (exec/console). Bare IDs wie
  `deepseek-v4-flash-latest` → 404. Erreichbare IDs:
  `$NODE $BW models --base-url https://inference-api.nousresearch.com/v1`.
- Backends: Pi-Extension nutzt Chromium-Fork 150; `exec`/Console nutzen
  CloakBrowser 146. Profile sind NICHT austauschbar → Backend-Wechsel
  erzeugt "upgraded by a newer Chromium"-Fehler. Fix: Daemons stoppen
  (`$NODE $BW close --all`), Profil beiseite legen
  (`mv ~/.betterwright/browser/profile{,.stale}`), neu starten.
  Vault überlebt. Hier bereits erledigt (`profile.stale-150*`).
- Profile-Lock: Läuft ein anderer BetterWright-Prozess, nutzt der neue
  eine temporäre Profile (Warnung "Another BetterWright process owns …").
  Lock nach Crash verfällt nach ~1 min von selbst.
- Session "default" persistiert bei exec/console (Folge-Tasks erben
  Browser + Konversation).

## Troubleshooting

- `betterwright doctor`: $NODE $BW doctor — Backend + Probleme.
- Sessions/Daemon: $NODE $BW sessions; stoppen: $NODE $BW close --all.
- Transiente 5xx/Timeout: 30–60 s mit Backoff retryen, erst dann "down".
- `reason` im exec-Ergebnis lesen: timeout / no_progress / interrupted …

## Sofort-Start: Seite öffnen + URI ausgeben (Standardweg)

Aufgabe "öffne <URL>" / "betterwright uri?" — der AKTIVE Agent macht das
selbst mit EINEM `extensions.browser`-Call. Kein `exec`, kein zweites
Modell, keine Token-Kosten für einen fremden Agenten:

```ts
await tools.call({ ref: 'extensions.browser', args: {
  code: `await page.goto('https://jannis.nix-dev.link', { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(1500);  // client-rendered Apps kurz warten lassen
        return { url: page.url(), title: await page.title() };`,
  note: 'Opening jannis.nix-dev.link'
}});
// → result: { url: "https://jannis.nix-dev.link/", title: "jannis" }  ← das ist die URI
```

Regeln:
- **URI = `page.url()`** aus dem Ergebnis — direkt an den User geben.
- Kein `close --all`, kein `pkill`, kein Profil-Move, kein Live-View-Start
  fürs bloße Öffnen/Lesen. Destruktive Schritte nur bei echtem Bedarf
  (Backend-Wechsel, siehe "Verifizierte Fakten").
- Warnung "Another BetterWright process owns …" = temporäre Profile: für
  Öffnen/Lesen egal, für Logins erst den Konflikt lösen (Lock verfällt
  nach ~1 min von selbst).
- **Live-View-Konsole NUR bei explizitem Zuschauer-Wunsch**: sie startet
  ein eigenes Modell (claude-opus-5-fast) → Token-Kosten. Konsole und
  Extension teilen die Profile NICHT; wer läuft, hat den Browser. Kommando
  und Tunnel: siehe Abschnitt "Live View / Zuschauen" oben.
