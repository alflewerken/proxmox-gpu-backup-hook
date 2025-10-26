# Proxmox GPU Backup Hook 🔧

[🇬🇧 English](README.md) | 🇩🇪 Deutsch

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-7.x%20%7C%208.x-orange.svg)](https://www.proxmox.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub issues](https://img.shields.io/github/issues/alflewerken/proxmox-gpu-backup-hook)](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)

**Automatische Backup-Lösung für Proxmox VMs mit GPU-Passthrough. Verhindert Backup-Fehler durch GPU-Konflikte. Ein-Zeilen-Installation.**

> **"Von einem Proxmox-Admin für Proxmox-Admins"**
>
> Nach stundenlangen fehlgeschlagenen Backup-Jobs und manuellem VM-Management habe ich diesen Hook gebaut, um zu automatisieren, was automatisch sein sollte. Wenn Sie mehrere VMs mit GPU-Passthrough betreiben, erspart Ihnen das die Kopfschmerzen, die ich hatte.

## ⭐ Unterstützen Sie das Projekt

Wenn Sie dieses Projekt nützlich finden, geben Sie ihm bitte einen Stern! Das hilft anderen, die Lösung zu entdecken und motiviert die weitere Entwicklung.

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/network)

</div>

---

## 🎯 Das Problem

Wenn mehrere Proxmox VMs dieselbe physische GPU teilen (GPU-Passthrough), können sie nicht gleichzeitig laufen. Bei Backup-Operationen führt dies dazu, dass VMs übersprungen werden, wenn eine andere VM die gemeinsame GPU bereits nutzt.

**Reales Szenario:**
```
VM 100: Windows Gaming PC     ─┐
VM 101: Ubuntu ML Workstation ─┼─ Alle nutzen RTX 4090 (01:00.0)
VM 102: AI Development Box    ─┘

Backup startet um 02:00 Uhr:
  ✅ VM 100 wird gesichert (lief, wird gestoppt)
  ❌ VM 101 ÜBERSPRUNGEN! GPU-Konflikt mit VM 100
  ❌ VM 102 ÜBERSPRUNGEN! GPU-Konflikt mit VM 100
  
Ergebnis: 66% Backup-Fehlerrate 😱
```

## ✅ Die Lösung

Dieses Hook-Skript bietet intelligente GPU-Konfliktauflösung:

✅ **Automatische GPU-Konflikterkennung** - Scannt PCI-Konfigurationen zur Identifikation gemeinsam genutzter GPUs  
✅ **Intelligente VM-Orchestrierung** - Stoppt konkurrierende VMs vor dem Backup-Start  
✅ **Sequentielle Backup-Verarbeitung** - Sichert alle VMs nacheinander  
✅ **Automatischer VM-Neustart** - Startet ursprünglich laufende VMs nach Backup-Abschluss  
✅ **Multi-GPU-Unterstützung** - Behandelt mehrere GPUs mit verschiedenen VM-Gruppen  
✅ **Intel SR-IOV kompatibel** - Funktioniert mit Intel iGPU Virtual Functions  
✅ **Umfassendes Logging** - Detaillierte Logs mit automatischer Rotation  

**Ergebnis nach Installation dieses Hooks:**
```
Backup startet um 02:00 Uhr:
  ✅ VM 100 wird gesichert (laufende VMs auto-gestoppt)
  ✅ VM 101 wird gesichert (Konflikte automatisch aufgelöst)
  ✅ VM 102 wird gesichert (sequentielle Verarbeitung)
  ✅ Alle ursprünglich laufenden VMs neu gestartet
  
Ergebnis: 100% Backup-Erfolgsrate! 🎉
```

---

## 🚀 Schnellstart - Ein-Zeilen-Installation

Installieren Sie das komplette Hook-System mit einem einzigen Befehl:

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

**Manuelle Installation:**
```bash
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh
```

Der Installer wird:
- ✅ Das Hook-Skript unter `/usr/local/bin/backup-gpu-hook.sh` erstellen
- ✅ Proxmox Backup-Hooks in `/etc/vzdump.conf` konfigurieren
- ✅ Log-Rotation in `/etc/logrotate.d/` einrichten
- ✅ Beispiel-Konfiguration mit Ihren VMs generieren
- ✅ Die Installation testen

---

## 🔧 Konfiguration

### Schritt 1: GPU-Gruppen konfigurieren

Bearbeiten Sie das Hook-Skript, um Ihre GPU-zu-VM-Zuordnungen zu definieren:

```bash
nano /usr/local/bin/backup-gpu-hook.sh
```

Suchen Sie den `TODO`-Abschnitt und konfigurieren Sie Ihr Setup:

```bash
# GPU-zu-VM-Zuordnung
# Format: GPU_GROUPS["PCI_ADRESSE"]="VM_ID1 VM_ID2 VM_ID3"
declare -A GPU_GROUPS

# Beispiel 1: Eine GPU geteilt von 3 VMs
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090

# Beispiel 2: Mehrere GPUs
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090 #1
GPU_GROUPS["05:00.0"]="110 111"      # RTX 3090 Ti

# Beispiel 3: Intel SR-IOV Virtual Functions
GPU_GROUPS["00:02.1"]="200"  # Intel UHD VF1
GPU_GROUPS["00:02.2"]="201"  # Intel UHD VF2
GPU_GROUPS["00:02.3"]="202"  # Intel UHD VF3
```

**PCI-Adressen finden:**
```bash
# Alle GPUs auflisten
lspci | grep VGA

# VM GPU-Zuordnungen finden
grep hostpci /etc/pve/qemu-server/*.conf
```

### Schritt 2: Konfiguration testen

```bash
# Hook manuell testen
/usr/local/bin/backup-gpu-hook.sh job-start test

# Log-Ausgabe prüfen
cat /var/log/vzdump-gpu-hook.log
```

### Schritt 3: Backup-Job erstellen

Backup-Job über die Proxmox WebUI konfigurieren:

1. Navigieren Sie zu **Datacenter → Backup → Add**
2. Zeitplan konfigurieren (z.B. `02:00` für 2 Uhr morgens)
3. Modus auf **Stop** setzen (erforderlich für GPU-Passthrough-VMs)
4. Backup-Storage auswählen
5. VMs zum Backup auswählen

Der Hook wird automatisch GPU-Konflikte während des Backups verwalten.

---

## 📋 Unterstützte Szenarien

| Szenario | Status | Hinweise |
|----------|--------|----------|
| NVIDIA GPUs (GeForce, Quadro, Tesla) | ✅ Unterstützt | Vollständiges PCI-Passthrough |
| AMD GPUs (Radeon, Instinct) | ✅ Unterstützt | Vollständiges PCI-Passthrough |
| Intel GPUs (UHD, Arc) | ✅ Unterstützt | Inklusive SR-IOV VFs |
| Mehrere GPUs mit verschiedenen VMs | ✅ Unterstützt | Separate GPU_GROUPS pro Gerät |
| Gemischte VM/CT-Umgebungen | ✅ Unterstützt | Container-Backups nicht betroffen |
| Automatischer VM-Neustart nach Backup | ✅ Unterstützt | Stellt Laufzustand wieder her |
| Einzelne GPU geteilt von 10+ VMs | ✅ Unterstützt | Sequentielle Verarbeitung |

---

## 🔍 Funktionsweise

### Hook-Ausführungsablauf

```
Backup-Job startet (02:00)
│
├─ 1. job-start Hook
│   ├─ Aktuellen Status laufender VMs speichern
│   └─ Tracking-Variablen initialisieren
│
├─ 2. backup-start Hook (für jede VM)
│   ├─ Von aktueller VM genutzte GPU identifizieren
│   ├─ Andere VMs mit gleicher GPU finden
│   ├─ Konkurrierende VMs stoppen
│   └─ Backup fortsetzen lassen
│
├─ 3. backup-end Hook (für jede VM)
│   ├─ Backup abgeschlossen
│   └─ Erfolg/Fehler protokollieren
│
└─ 4. job-end Hook
    ├─ Alle ursprünglich laufenden VMs neu starten
    └─ Temporäre Status-Dateien aufräumen
```

### Detailliertes Beispiel

```
Ausgangszustand:
  VM 100 (RTX 4090) - Läuft
  VM 101 (RTX 4090) - Gestoppt
  VM 102 (RTX 4090) - Läuft

Backup-Prozess:
  
  1. Job Start
     └─ Gespeicherter Status: VMs 100,102 liefen
  
  2. Backup VM 100
     ├─ GPU 01:00.0 wird von VM 102 genutzt
     ├─ VM 102 temporär stoppen
     ├─ VM 100 sichern
     └─ Erfolg
  
  3. Backup VM 101
     ├─ Keine GPU-Konflikte (VM 100 durch Backup gestoppt)
     ├─ VM 101 sichern
     └─ Erfolg
  
  4. Backup VM 102
     ├─ Keine GPU-Konflikte (andere VMs gestoppt)
     ├─ VM 102 sichern
     └─ Erfolg
  
  5. Job Ende
     └─ VMs 100 und 102 neu starten (liefen ursprünglich)

Endzustand:
  VM 100 (RTX 4090) - Läuft ✅
  VM 101 (RTX 4090) - Gestoppt ✅
  VM 102 (RTX 4090) - Läuft ✅
```

---

## 📊 Dateien und Verzeichnisse

Das Setup-Skript erstellt folgende Struktur:

```
/usr/local/bin/
└─ backup-gpu-hook.sh              # Haupt-Hook-Skript (ausführbar)

/etc/
└─ vzdump.conf                     # Proxmox Backup-Konfiguration
                                   # (hookscript-Referenz hinzugefügt)

/etc/logrotate.d/
└─ vzdump-gpu-hook                 # Log-Rotations-Konfiguration
                                   # (tägliche Rotation, 7 Tage Aufbewahrung)

/var/log/
└─ vzdump-gpu-hook.log            # Detailliertes Betriebs-Log

/tmp/
└─ gpu-backup-example.txt         # Generierte Beispiel-Konfiguration
                                   # (basierend auf Ihren tatsächlichen VMs)
```

---

## 🛠️ Fehlerbehebung

### Logs prüfen

```bash
# Aktuelle Log-Einträge anzeigen
tail -100 /var/log/vzdump-gpu-hook.log

# Logs in Echtzeit verfolgen
tail -f /var/log/vzdump-gpu-hook.log

# Nach Fehlern suchen
grep ERROR /var/log/vzdump-gpu-hook.log
```

### Häufige Probleme

#### VMs werden nicht gestoppt

**Symptome:**
- Backups schlagen weiterhin mit GPU-Konflikten fehl
- Log zeigt keine VM-Stopp-Aktionen

**Lösung:**
```bash
# 1. GPU_GROUPS-Konfiguration überprüfen
grep "GPU_GROUPS\[" /usr/local/bin/backup-gpu-hook.sh

# 2. Tatsächliche PCI-Adressen prüfen
lspci | grep VGA

# 3. VM-Konfigurationen verifizieren
grep hostpci /etc/pve/qemu-server/*.conf

# 4. Sicherstellen, dass PCI-Adressen zwischen Config und VM-Definitionen übereinstimmen
```

#### Hook wird nicht ausgeführt

**Symptome:**
- Keine Log-Einträge während des Backups
- Backups laufen ohne Hook-Eingriff

**Lösung:**
```bash
# 1. vzdump.conf prüfen
cat /etc/vzdump.conf | grep hookscript

# Sollte zeigen:
# hookscript: /usr/local/bin/backup-gpu-hook.sh

# 2. Verifizieren, dass Hook-Skript ausführbar ist
ls -la /usr/local/bin/backup-gpu-hook.sh

# Sollte zeigen: -rwxr-xr-x

# 3. Hook manuell testen
/usr/local/bin/backup-gpu-hook.sh job-start test
```

#### VMs starten nach Backup nicht neu

**Symptome:**
- Backup erfolgreich, aber VMs bleiben gestoppt
- Ursprünglich laufende VMs starten nicht automatisch

**Lösung:**
```bash
# 1. job-end Hook-Ausführung prüfen
grep "job-end" /var/log/vzdump-gpu-hook.log

# 2. Status-Datei während Backup verifizieren
ls -la /tmp/gpu-backup-running-vms-*

# 3. Auf Fehler im Log prüfen
grep ERROR /var/log/vzdump-gpu-hook.log | tail -20
```

### Manuelles Testen

Kompletten Hook-Workflow manuell testen:

```bash
# 1. Job starten (initialisiert Tracking)
/usr/local/bin/backup-gpu-hook.sh job-start test-$(date +%s)

# 2. Backup von VM 100 simulieren
/usr/local/bin/backup-gpu-hook.sh backup-start 100

# 3. VM 100 Backup abschließen
/usr/local/bin/backup-gpu-hook.sh backup-end 100

# 4. Job beenden (startet VMs neu)
/usr/local/bin/backup-gpu-hook.sh job-end test-$(date +%s)

# 5. Log überprüfen
cat /var/log/vzdump-gpu-hook.log | tail -50
```

---

## 🖥️ Beispiel-Konfigurationen

### Konfiguration 1: Dual RTX 4090 Setup

**Hardware:**
- 2× NVIDIA RTX 4090
- 6 VMs insgesamt (3 pro GPU)

**Konfiguration:**
```bash
declare -A GPU_GROUPS
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090 #1 (Gaming, ML, Rendering)
GPU_GROUPS["02:00.0"]="110 111 112"  # RTX 4090 #2 (Entwicklung, Testing, Demo)
```

### Konfiguration 2: Intel SR-IOV mit Virtual Functions

**Hardware:**
- Intel UHD Graphics 770
- 7 Virtual Functions aktiviert
- 7 VMs nutzen VFs

**Konfiguration:**
```bash
declare -A GPU_GROUPS
GPU_GROUPS["00:02.1"]="200"  # Desktop VM
GPU_GROUPS["00:02.2"]="201"  # Media Server
GPU_GROUPS["00:02.3"]="202"  # Entwicklung
GPU_GROUPS["00:02.4"]="203"  # Testing
GPU_GROUPS["00:02.5"]="204"  # Produktion Web
GPU_GROUPS["00:02.6"]="205"  # Staging
GPU_GROUPS["00:02.7"]="206"  # Demo-Umgebung
```

### Konfiguration 3: Gemischte GPU-Umgebung

**Hardware:**
- 1× NVIDIA RTX 4090 (01:00.0)
- 1× NVIDIA RTX 3090 Ti (05:00.0)
- 1× AMD Radeon RX 7900 XTX (08:00.0)
- Intel UHD mit SR-IOV (00:02.x)

**Konfiguration:**
```bash
declare -A GPU_GROUPS
# NVIDIA Karten
GPU_GROUPS["01:00.0"]="100 101 102"     # RTX 4090 (High-End Workloads)
GPU_GROUPS["05:00.0"]="110 111"         # RTX 3090 Ti (ML Training)

# AMD Karte
GPU_GROUPS["08:00.0"]="120 121 122"     # RX 7900 XTX (Rendering Farm)

# Intel SR-IOV
GPU_GROUPS["00:02.1"]="200"             # Leichte Desktop-Arbeit
GPU_GROUPS["00:02.2"]="201"             # Office-Anwendungen
```

---

## 📝 Anforderungen

- **Proxmox VE**: Version 7.x oder 8.x
- **Shell**: Bash 4.0 oder höher
- **Berechtigungen**: Root-Zugriff für Installation erforderlich
- **VMs**: Konfiguriert mit GPU-Passthrough (`hostpci`-Parameter)
- **Backup-Modus**: VMs müssen `stop`-Modus für Backup verwenden (erforderlich für GPU-Passthrough)

---

## 🤝 Mitwirken

Beiträge sind willkommen! Ob Bug-Reports, Feature-Requests oder Code-Verbesserungen.

### Möglichkeiten zur Mitarbeit

1. **Probleme melden**: Bug gefunden? [Issue öffnen](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
2. **Features vorschlagen**: Eine Idee? Lassen Sie uns darüber diskutieren!
3. **Pull Requests einreichen**: Code-Verbesserungen sind immer willkommen
4. **Ihr Setup teilen**: Helfen Sie anderen, indem Sie Ihre GPU-Konfiguration teilen
5. **Repo einen Stern geben**: Wenn dies Ihr Problem gelöst hat, geben Sie einen ⭐

### Entwicklungsumgebung

```bash
# Repository klonen
git clone https://github.com/alflewerken/proxmox-gpu-backup-hook.git
cd proxmox-gpu-backup-hook

# Auf Ihrem Proxmox-Server testen
scp setup-gpu-backup-hook.sh root@ihr-proxmox-server:/tmp/
ssh root@ihr-proxmox-server
cd /tmp && ./setup-gpu-backup-hook.sh
```

Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für detaillierte Richtlinien.

---

## 📜 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE)-Datei für Details.

**Kurz gesagt:** Frei verwendbar für private und kommerzielle Zwecke. Keine Garantie gewährt.

---

## 💡 Hintergrund

Dieses Skript entstand aus echter Frustration beim Verwalten eines Proxmox-Homelabs mit mehreren VMs, die GPUs teilen. Nach unzähligen fehlgeschlagenen Backup-Jobs und manuellem VM-Management entschied ich mich, zu automatisieren, was automatisch sein sollte.

Das Ziel war einfach: **Proxmox-Backups "einfach funktionieren" lassen mit GPU-Passthrough.**

Wenn Sie AI-Workstations, Gaming-VMs, Rendering-Farmen oder irgendein Setup mit gemeinsam genutzten GPUs betreiben, wird Ihnen dieser Hook die Kopfschmerzen ersparen, die ich beim Aufbau und Verwalten dieser Systeme hatte.

---

## 🙏 Danksagungen

- **Proxmox VE Team** - Für die exzellente Virtualisierungsplattform
- **Die Proxmox Community** - Für das Teilen von Wissen und Troubleshooting-Tipps
- **GPU-Passthrough-Pioniere** - Für die Dokumentation des komplexen Setup-Prozesses

---

## 💬 Über

> *"Nach über 30 Jahren im Management von Rechenzentrumsinfrastruktur (SGI, Sun, IBM) und dem Aufbau mehrerer AI-Workstation-Unternehmen weiß ich, wie es ist, mit Hardware-Passthrough zu kämpfen. Dieser Hook ist mein Beitrag, um das Leben für Sysadmins und Homelab-Enthusiasten einfacher zu machen."*
>
> *- Alf, Systemadministrator & Proxmox-Nutzer seit 2019*

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/alflewerken">Alf Lewerken</a><br>
  <i>Von einem Proxmox-Admin für Proxmox-Admins</i>
</p>

---

**⭐ Wenn dieser Hook Ihre Backups gerettet hat, geben Sie dem Repo einen Stern!**
