# Proxmox GPU Backup Hook 🔧

[🇬🇧 English](README.md) | 🇩🇪 Deutsch

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-7.x%20%7C%208.x-orange.svg)](https://www.proxmox.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-2.4-blue.svg)](CHANGELOG.md)
[![GitHub issues](https://img.shields.io/github/issues/alflewerken/proxmox-gpu-backup-hook)](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)

**Null-Konfigurations-Backup-Lösung für Proxmox VMs mit GPU-Passthrough. Verhindert Backup-Fehler durch GPU-Konflikte. Ein-Zeilen-Installation - keine manuelle Konfiguration erforderlich!**

> **"Von einem Proxmox-Admin für Proxmox-Admins"**
>
> Nach stundenlangen fehlgeschlagenen Backup-Jobs habe ich diesen Hook entwickelt. Version 2.4 behebt kritische Fehler aus der Praxis - **VMs starten jetzt auch nach Backup-Fehlern zuverlässig neu!**

## 🆕 Neu in Version 2.4

🔥 **KRITISCHER FIX: Race Condition** - VMs starten nach Backup-Fehlern wieder  
🔥 **KRITISCHER FIX: Backup-Abort** - VMs starten auch bei Backup-Abbruch neu  
✨ **Zuverlässiger Restart** - Alle VMs werden korrekt erfasst, keine Status-Checks  
✨ **Guest-Agent unabhängig** - Funktioniert perfekt ohne qemu-guest-agent  
✨ **Produktions-getestet** - Behebt reale Probleme aus Produktionsumgebungen

**Das Problem (Behoben in v2.4):**
```bash
# Race Condition Timeline:
# T1: vzdump startet VM-Shutdown
# T2: Hook prüft is_vm_running() → false (bereits am Herunterfahren)
# T3: VM wird nicht für Restart aufgezeichnet
# T4: Backup schlägt fehl → VM bleibt gestoppt ❌

# v2.4 Fix:
# VMs werden immer für Restart aufgezeichnet, keine Status-Checks ✅
# Funktioniert mit allen Backup-Modi und Fehlerszenarien ✅  

---

## 🎯 Das Problem

Wenn mehrere Proxmox VMs dieselbe physische GPU teilen (GPU-Passthrough), können sie nicht gleichzeitig laufen. Bei Backups werden VMs übersprungen, wenn eine andere VM die GPU nutzt.

**Reales Szenario:**
```
VM 100: Windows Gaming PC     ─┐
VM 101: Ubuntu ML Workstation ─┼─ Alle nutzen RTX 4090 (01:00.0)
VM 102: AI Development Box    ─┘

Backup startet um 02:00:
  ✅ VM 100 wird gesichert
  ❌ VM 101 ÜBERSPRUNGEN! GPU-Konflikt
  ❌ VM 102 ÜBERSPRUNGEN! GPU-Konflikt
  
Ergebnis: 66% Fehlerrate 😱
```

## ✅ Die Lösung

Intelligente GPU-Konfliktauflösung - **ohne Konfiguration**:

✅ **Automatische GPU-Erkennung** - Scannt dynamisch VM-Konfigurationen  
✅ **Null manuelle Einrichtung** - Keine GPU-Gruppen konfigurieren  
✅ **Intelligente VM-Orchestrierung** - Stoppt VMs vor Backup automatisch  
✅ **Sequentielle Verarbeitung** - Sichert alle VMs nacheinander  
✅ **Automatischer Neustart** - Startet VMs nach Backup wieder  
✅ **Multi-GPU-Support** - Behandelt unbegrenzt viele GPUs automatisch  
✅ **Intel SR-IOV kompatibel** - Funktioniert mit Intel iGPU VFs  
✅ **Container-Support** - Verwaltet VMs und LXC-Container  
✅ **Zukunftssicher** - Passt sich automatisch an Änderungen an  

**Ergebnis nach Installation:**
```
Backup startet um 02:00:
  ✅ VM 100 gesichert (Konflikte auto-aufgelöst)
  ✅ VM 101 gesichert (GPU-Sharing automatisch verwaltet)
  ✅ VM 102 gesichert (sequentielle Verarbeitung)
  ✅ Alle VMs automatisch neu gestartet
  
Ergebnis: 100% Erfolgsrate! 🎉
```

---

## 🚀 Schnellstart - Ein-Zeilen-Installation

Installiere das komplette System mit einem Befehl - **keine Konfiguration nötig**:

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

**Manuelle Installation:**
```bash
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh
```

**Der Installer automatisch:**
- ✅ Lädt Hook-Script herunter und installiert es
- ✅ Konfiguriert Proxmox Backup-Hooks
- ✅ Richtet Log-Rotation ein
- ✅ Testet die Installation
- ✅ Scannt und erkennt GPU-VMs
- ✅ **Keine manuelle Konfiguration erforderlich!**

---

## 🎮 Verwendung - Es funktioniert einfach!

### Schritt 1: Installation (Bereits erledigt)

Ein Befehl, vollautomatisch. Das war's!

### Schritt 2: Backup-Job erstellen

Backup-Job über Proxmox WebUI konfigurieren:

1. **Datacenter → Backup → Add**
2. Zeitplan konfigurieren (z.B. `02:00`)
3. Modus auf **Stop** setzen (bereits konfiguriert)
4. Backup-Storage auswählen
5. VMs zum Backup auswählen

**Der Hook verwaltet alle GPU-Konflikte automatisch!**

### Schritt 3: Überwachen (Optional)

Erstes Backup beobachten:

```bash
tail -f /var/log/vzdump-gpu-hook.log
```

Sie sehen den Hook automatisch:
- VMs und GPU-Zuordnungen erkennen
- GPU-Konflikte identifizieren
- VMs bei Bedarf stoppen/starten
- Alles automatisch verwalten

---

## 🔍 Funktionsweise

**Vor jedem Backup:**
```
1. Hook scannt alle VM/CT-Konfigurationen in /etc/pve/
2. Extrahiert GPU-PCI-Adressen aus hostpci-Einstellungen
3. Erstellt dynamische Map welche VMs welche GPUs teilen
4. Identifiziert Konflikte für die aktuelle Backup-VM
5. Stoppt konfliktverursachende VMs temporär
6. Führt Backup durch
7. Startet gestoppte VMs nach Job-Abschluss neu
```

---

## 🛠️ Fehlerbehebung

### Logs prüfen

```bash
# Aktuelle Aktivität anzeigen
tail -100 /var/log/vzdump-gpu-hook.log

# Echtzeit verfolgen
tail -f /var/log/vzdump-gpu-hook.log

# Nach Problemen suchen
grep -E "(ERROR|WARNING)" /var/log/vzdump-gpu-hook.log
```

### Häufige Fragen

**"Funktioniert es?"**

Prüfen Sie das Log nach dem ersten Backup:
```bash
cat /var/log/vzdump-gpu-hook.log
```

**"Muss ich etwas konfigurieren?"**

**Nein!** Version 2.0 ist vollautomatisch. Das Script:
- Scannt VMs automatisch
- Erkennt GPU-Zuordnungen
- Verwaltet Konflikte dynamisch
- Passt sich Änderungen automatisch an

**"Was wenn ich eine neue VM mit GPU hinzufüge?"**

Nichts! Der Hook erkennt sie beim nächsten Backup automatisch.

**"Was wenn ich die GPU einer VM ändere?"**

Der Hook erkennt die Änderung beim nächsten Backup automatisch.

---

## 🔄 Upgrade von Version 1.0

Wenn Sie von Version 1.0 upgraden:

```bash
# Neuen Installer herunterladen
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh

# Installer ausführen (upgraded automatisch)
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh

# Fertig! Keine Konfigurations-Migration nötig.
```

**Vorteile des Upgrades:**
- ✅ Alle manuellen GPU-Gruppen-Konfigurationen entfernen
- ✅ Automatische Erkennung aller VMs
- ✅ Keine Wartung bei VM-Änderungen
- ✅ Support für Container (LXC)
- ✅ Bessere Fehlerbehandlung

---

## 📝 Anforderungen

- **Proxmox VE**: Version 7.x oder 8.x
- **Shell**: Bash 4.0+ (Standard auf Proxmox)
- **Berechtigungen**: Root-Zugriff für Installation
- **VMs**: Mit GPU-Passthrough (`hostpci`-Parameter)
- **Backup-Modus**: Wird automatisch auf `stop` gesetzt
- **Internet**: Für initiale Installation

**Keine weiteren Abhängigkeiten!** Funktioniert mit Standard-Proxmox.

---

## 🤝 Mitwirken

Beiträge sind willkommen!

### Möglichkeiten zur Mitarbeit

1. **⭐ Repo einen Stern geben**: Helfen Sie anderen, die Lösung zu finden
2. **🐛 Probleme melden**: [Issue öffnen](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
3. **💡 Features vorschlagen**: Teilen Sie Ihre Ideen
4. **🔧 Pull Requests**: Code-Verbesserungen willkommen
5. **📖 Dokumentation**: Helfen Sie die Docs zu verbessern
6. **💬 Erfahrungen teilen**: Berichten Sie über Ihr Setup

Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Details.

---

## 📜 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE).

**Kurz gesagt:**
- ✅ Frei für private und kommerzielle Nutzung
- ✅ Frei modifizierbar und verteilbar
- ✅ Keine Garantie (auf eigenes Risiko)

---

## 💡 Hintergrund

Dieses Script entstand aus echter Frustration beim Verwalten eines Proxmox-Homelabs mit GPU-sharing VMs. Nach unzähligen fehlgeschlagenen Backups entschied ich mich zu automatisieren, was automatisch sein sollte.

**Version 2.0** erreicht die ursprüngliche Vision: **Proxmox-Backups "funktionieren einfach" mit GPU-Passthrough - automatisch!**

Wenn Sie betreiben:
- 🎮 Gaming-VMs
- 🤖 AI/ML-Workstations
- 🎨 Rendering-Farmen
- 💻 Entwicklungsumgebungen
- 🏠 Homelab mit GPU-Passthrough

Wird dieser Hook Ihnen die Kopfschmerzen ersparen, die ich hatte.

---

## 🙏 Danksagungen

- **Proxmox VE Team** - Für die exzellente Plattform
- **Proxmox Community** - Für Wissen und Troubleshooting
- **GPU-Passthrough-Pioniere** - Für die Dokumentation
- **Early Adopters** - Für Tests und Feedback
- **Contributors** - Für Verbesserungen

---

## 💬 Über den Autor

> *"Nach 30+ Jahren Rechenzentrumsinfrastruktur (SGI, Sun, IBM) und dem Aufbau mehrerer AI-Workstation-Firmen weiß ich, wie es ist, mit Hardware-Passthrough zu kämpfen. Dieser Hook ist mein Beitrag, um das Leben für Sysadmins einfacher zu machen."*
>
> *- Alf Lewerken, Systemadministrator & Proxmox-Nutzer seit 2019*

---

<p align="center">
  <b>Made with ❤️ by <a href="https://github.com/alflewerken">Alf Lewerken</a></b><br>
  <i>Von einem Proxmox-Admin für Proxmox-Admins</i><br><br>
  <b>⭐ Wenn dieser Hook Ihre Backups gerettet hat, geben Sie dem Repo einen Stern! ⭐</b>
</p>

---

**Weitere Ressourcen:**
- 📖 [Vollständige englische Dokumentation](README.md)
- 📝 [Changelog](CHANGELOG.md)
- 🤝 [Contributing Guide](CONTRIBUTING.md)
- 🐛 [Issue Tracker](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
