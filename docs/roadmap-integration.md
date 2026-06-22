# Projektstatus & Integrations-Roadmap

*Einfache Übersicht (wenig Fachjargon) über die host-native MVS-Toolchain und
was noch fehlt, um sie in die MVS-Projekte (crent370, httpd, mvsmf, …) zu
integrieren. Stand: 2026-06.*

## Worum es geht (ein Satz)

Mainframe-Programme **komplett auf dem PC** (Mac/Linux) bauen und nur das fertige
Programm zum MVS schicken — statt wie früher Quellcode hochzuladen und auf dem
Mainframe zu übersetzen + binden (langsam, viele Jobs).

## Die vier Werkzeuge

| Werkzeug | macht |
|----------|-------|
| **cc370** | C-Code → Mainframe-Assembler |
| **as370** | Assembler → Objektdatei |
| **ld370** | Objektdateien → fertiges Programm + Transport-Paket (XMIT) |
| **ar370** | Objektdateien → Bibliothek (`.a`), aus der ld370 automatisch nur das Benötigte zieht |

## Was funktioniert (auf echtem MVS bewiesen)

- **Kompletter Weg für ein einfaches Programm:** übersetzen → assemblieren →
  binden → verpacken → hochladen → installieren → **läuft** (Testprogramm,
  Rückgabewert 7 wie erwartet). Kein IFOX / IEWL / IEBCOPY mehr im Spiel.
- **Bibliotheken:** Die C-Laufzeit (crent370) wird archiviert; ld370 zieht beim
  Binden automatisch genau die gebrauchten Teile (wie ein echter Linker).
- **Transport-Format (XMIT):** byte-genau gegen die echten Mainframe-Werkzeuge
  und eine unabhängige Referenz-Implementierung geprüft.

## Was fast fertig ist

Ein **echtes** C-Programm (das die C-Laufzeit nutzt) lässt sich jetzt
**vollständig auf dem PC binden** (alle Teile aufgelöst, korrekt verdrahtet). Es
**läuft nur noch nicht** — beim Verpacken großer Programme fehlt ein Detail
(„Multi-Track", siehe A1). Das ist der letzte Schritt zum ersten echten
host-gebauten C-Programm.

---

## Offene Punkte (für die Integration in die MVS-Projekte)

### A. Toolchain fertig (Pflicht — damit echte Programme laufen)

1. **Multi-Text-Modul läuft beim FETCH durch** — ✅ **BEHOBEN (2026-06-21).** Es war
   weder FETCH noch Geometrie noch Emission-vs-IEWL: `ld370`s Per-Objekt-Textpuffer
   war ein fixes 16384-Byte-Array (`struct obj.text[1<<14]`), und der TXT-Reader
   verwarf jede Card jenseits 16 K **still** → Modul ab ~16 KB genullt → S0C1 beim
   Lauf. Fix: dynamisch wachsender Puffer. NOPT 17000/2056 + 12288/12288 laufen
   RC=0, Fixtures byte-identisch zu IEWL. (Details: `docs/multitext-fetch-truncation.md`.)
   **U0200 ebenfalls behoben** (2026-06-21): eine einzelne CSECT > MAXTEXT wird jetzt
   intra-section in ≤MAXTEXT-Records gesplittet (IEWL-Layout, Orakel
   `run_iewl_bigsect.py`); 60-KB-Modul installiert + läuft RC=0.
   **t1 (echtes C-Programm) Stand:** Transport läuft jetzt (RECV RC=0, ~69 KB/11 Tracks);
   **RUN bricht mit S106** (Program-FETCH) — neue Frontier (t1 hat echte RLDs/141 Sektionen/
   entry=8). Das ist der nächste Schritt für „ein C-Programm läuft".
2. **Globale Variablen (CM)** — noch nicht getestet; evtl. braucht ld370 dafür
   eine Kleinigkeit.
3. **Module ohne Standard-Start (no-crt0)** — httpd/mvsmf haben Programme, die
   *nicht* die normale C-Startroutine nutzen. Dafür braucht cc370/ld370 eine
   Schalter-Option (`-nostartfiles`-Stil).
4. **Einstellbarer Einstiegspunkt (`-e`)** — die `project.toml` legt den
   Einstiegspunkt pro Modul fest (`entry = "@@CRT0"`); ld370 muss das übernehmen.

### B. Komfort

5. **cc370 als Ein-Befehl-Driver** — `cc370 prog.c -o prog -lmylib`, statt die
   vier Werkzeuge einzeln aufzurufen.
6. **crent als „eingebaute Standardbibliothek"** — Header/Libs nicht jedes Mal
   angeben müssen (cc370 kennt sie im Suchpfad).
7. **Build-Skript für `libcrent.a`** — aktuell wird die C-Laufzeit-Bibliothek
   noch von Hand gebaut.

### C. Build-System (mbt)

8. **mbt auf Host-Bau umstellen** — lokal bauen + binden, nur das XMIT
   hochladen (spart sehr viele JES-Jobs, deutlich schneller).
9. **Pro Projekt** Einstiegspunkte und Bibliotheks-Archive definieren.

### D. Feinschliff / Verallgemeinerung

10. Verzeichnis-Daten + Größen für beliebige Programme berechnen (aktuell teils
    Schablone).
11. Bibliotheken mit mehreren Membern (falls gebraucht).
12. **Lange Symbolnamen** (mittelfristig weg von 8-Zeichen-Namen; ar370s
    Symbolindex ist schon darauf vorbereitet).
13. as370/ld370-Optionen + Listings abrunden.

---

## Roadmap (Reihenfolge)

**Phase 1 — Toolchain rund** → *Ziel: erstes echtes C-Programm läuft auf MVS*
→ A1 Multi-Track · A2 globale Variablen · A3 no-crt0-Option · A4 einstellbarer Einstiegspunkt

**Phase 2 — Bequem** → *Ziel: Ein-Befehl-Bau ohne Handarbeit*
→ B5 cc370-Driver · B6 crent als Standardbibliothek · B7 libcrent.a-Skript

**Phase 3 — mbt-Integration** → *Ziel: ein Projekt komplett host-gebaut*
→ C8 mbt-Host-Backend · ein kleines Projekt als Pilot umstellen · dann httpd/mvsmf/… ausrollen

**Phase 4 — Feinschliff** → nach Bedarf (D10–D13)

---

## Wobei Infos helfen

1. **RECV370-Quellcode/Doku** — das Mainframe-Programm, das das XMIT entpackt.
   Dafür gibt es hier keine Quelle. Mit der Quelle wäre der Blocker **A1
   (Multi-Track)** deutlich schneller; sonst Reverse-Engineering per
   MVS-Experiment (geht auch, dauert länger).
2. **Ziel-System(e):** immer `mvsdev.lan`, oder auch TK4-/TK5/MVSCE? Platten-
   Geometrie und RECV370-Version können sich unterscheiden — relevant für A1.
3. **no-crt0-Module (A3):** welche genau in httpd/mvsmf, und wie gedacht
   (eigener Einstiegspunkt, keine C-Startroutine)? Ein, zwei Beispiele reichen.
4. **Ziel-Load-Libraries:** Blocksize/Gerät der echten LINKLIBs (z.B.
   `HTTPD.LINKLIB`) — fürs korrekte Verpacken. Größtenteils selbst von MVS
   abfragbar.

---

## Technische Referenzen (für Details)

- `CLAUDE.md` — Tooltabelle, ausführliche Roadmap (Punkte A–E), Build-Anleitung.
- `docs/object-module-format.md`, `docs/load-module-format.md` — die
  Objekt-/Load-Module-Formate (Grundlage für as370/ld370).
- `docs/unload-format.md`, `docs/xmit-format.md` — die Transport-Formate
  (Grundlage für `ld370 -iebcopy`/`-xmit`).
- `docs/multitext-fetch-truncation.md` — gelöster Blocker A1 (Multi-Text-Modul
  wurde bei 16 KB abgeschnitten — `ld370`-Textpuffer; 2026-06-21 behoben).
- `as370/` — as370 (host-nativer Assembler) inkl. eigener Doku.
