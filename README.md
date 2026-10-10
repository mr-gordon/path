# path

Kleine macOS-Menüleisten-App, die kopierte Windows-Netzwerkpfade automatisch in `smb://`-Links umwandelt – ein Klick öffnet sie im Finder.

```
\\brudefup1\Freigabe\Projekt   →   smb://brudefup1/Freigabe/Projekt
M:\Ordner\Datei                →   smb://brudefup1/design/Ordner/Datei   (M: → smb://brudefup1/design)
```

## Funktionen

- **Zwischenablage-Überwachung:** erkennt UNC-Pfade (`\\server\freigabe\…`) und Laufwerksbuchstaben (`M:\…`) und konvertiert sie sofort. Der Link kann automatisch in die Zwischenablage gelegt werden. Inhalte, die Passwortmanager als vertraulich markieren, werden ignoriert.
- **Popover:** der letzte Link als Button (Klick öffnet im Finder), darunter die letzten 10 Konvertierungen mit Kopieren-Button. Rechtsklick: `smb://`-Link oder ursprünglichen Windows-Pfad kopieren.
- **Laufwerks-Mappings:** Buchstaben frei Serverfreigaben zuordnen (`M:` → `smb://server/freigabe`).
- **Schnelles Öffnen:** bereits eingehängte Freigaben werden direkt geöffnet. Sonst prüft die App vorher kurz Port 445 und zeigt bei fehlendem Netzwerk/VPN einen Hinweis statt eines hängenden Finders.
- **Mitteilung** nach jeder Konvertierung, Autostart beim Anmelden, Verlauf optional beim Beenden verwerfen.

## Datenschutz

Alles läuft lokal. Es werden keine Anmeldedaten abgefangen oder gespeichert und nichts ins Netz gesendet (außer dem TCP-Check auf Port 445 des Servers, den Sie öffnen wollen).

## Installation

1. `path-1.0.5.zip` aus den [Releases](https://github.com/mr-gordon/path/releases) laden und entpacken.
2. `path.app` nach „Programme“ verschieben.
3. Die App ist nur ad-hoc signiert. Beim ersten Start: Rechtsklick → „Öffnen“, oder
   ```bash
   xattr -dr com.apple.quarantine /Applications/path.app
   ```

Voraussetzung: macOS 14 oder neuer.

## Selbst bauen

Benötigt Xcode bzw. die Command Line Tools (Swift 5.9+).

```bash
./build.sh                       # erzeugt build/path.app
swift test                       # Tests der Konvertierungslogik
swift tools/make-icons.swift     # App- und Menüleisten-Icon neu erzeugen
```

## Aufbau

| Pfad | Inhalt |
| --- | --- |
| `Sources/PathCore` | Konvertierung, Erreichbarkeits-Check, Erkennung eingehängter Volumes |
| `Sources/path` | SwiftUI-App (Menüleiste, Popover, Einstellungen) |
| `Tests/PathCoreTests` | Unit-Tests |
| `Resources` | `Info.plist`, Icons |

## Änderungen

**1.0.5** – Öffnen unerreichbarer Server hängt die App nicht mehr auf (Erreichbarkeits-Check zuerst, Mount-Suche im Hintergrund), Ladeanzeige beim Öffnen.
**1.0** – Erste Version.

## Lizenz

[MIT](LICENSE)
