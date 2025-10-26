# Proxmox GPU Backup Hook

**Automatische Lösung für Backup-Probleme bei GPU-Passthrough VMs**

## 🎯 Problem

Wenn mehrere Proxmox VMs dieselbe GPU teilen (GPU-Passthrough), können sie nicht gleichzeitig laufen. Bei Backups führt dies dazu, dass VMs übersprungen werden, wenn eine andere VM die GPU bereits nutzt.

**Beispiel:**
- VM 100 und VM 101 nutzen beide die gleiche RTX 4090
- VM 100 läuft gerade
- Backup-Job startet für VM 101
- ❌ VM 101 kann nicht starten → Backup schlägt fehl

## ✅ Lösung

Dieses Hook-Skript:
- Erkennt automatisch GPU-Konflikte
- Stoppt konkurrierende VMs vor dem Backup
- Sichert alle VMs nacheinander
- **Startet ursprünglich laufende VMs nach dem Backup wieder**

## 📦 Installation (1 Befehl)

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

Oder manuell:

```bash
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh
```

## 🔧 Konfiguration

Nach der Installation:

1. **GPU-Zuordnungen eintragen:**
   ```bash
   nano /usr/local/bin/backup-gpu-hook.sh
   ```
   
   Suche nach `TODO` und trage deine VMs ein:
   ```bash
   declare -A GPU_GROUPS
   GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090
   GPU_GROUPS["05:00.0"]="110 111"      # RTX 3090 Ti
   ```

2. **Testen:**
   ```bash
   /usr/local/bin/backup-gpu-hook.sh job-start test
   cat /var/log/vzdump-gpu-hook.log
   ```

3. **Backup-Job erstellen** (Proxmox WebUI):
   - Datacenter → Backup → Add
   - Schedule: z.B. `02:00`
   - Mode: `stop` (bereits konfiguriert)
   - Storage: Dein Backup-Storage

## 📋 Unterstützte Szenarien

✅ Mehrere VMs teilen eine GPU (NVIDIA, AMD, Intel)  
✅ Mehrere GPUs mit verschiedenen VMs  
✅ Intel SR-IOV Virtual Functions  
✅ Gemischte VM/Container Umgebungen  
✅ Automatischer Neustart von VMs nach Backup

## 🖥️ Beispiel-Konfigurationen

### NVIDIA GPUs
```bash
# 2x RTX 4090, jeweils 3 VMs pro GPU
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090 #1
GPU_GROUPS["02:00.0"]="110 111 112"  # RTX 4090 #2
```

### Intel SR-IOV
```bash
# Intel iGPU mit Virtual Functions
GPU_GROUPS["00:02.1"]="200"  # VF1
GPU_GROUPS["00:02.2"]="201"  # VF2
GPU_GROUPS["00:02.3"]="202"  # VF3
```

### Gemischt
```bash
# NVIDIA + Intel
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090
GPU_GROUPS["00:02.1"]="200"          # Intel UHD VF
```

## 🔍 Wie es funktioniert

```
Backup-Job startet um 02:00
├─ VM 100 (nutzt RTX 4090)
│  ├─ VM 101 läuft → Hook stoppt VM 101
│  ├─ VM 100 wird gesichert
│  └─ VM 100 startet wieder
├─ VM 101 (nutzt RTX 4090)
│  ├─ VM 100 läuft → Hook stoppt VM 100
│  ├─ VM 101 wird gesichert
│  └─ VM 101 startet wieder
└─ Job-Ende
   └─ Hook startet alle gestoppten VMs wieder
```

## 📊 Dateien

Das Setup-Skript erstellt:

```
/usr/local/bin/backup-gpu-hook.sh       # Hook-Skript
/etc/vzdump.conf                         # Proxmox Backup-Konfiguration
/etc/logrotate.d/vzdump-gpu-hook        # Log-Rotation
/var/log/vzdump-gpu-hook.log            # Log-Datei
/tmp/gpu-backup-example.txt             # Beispiel-Konfiguration
```

## 🛠️ Troubleshooting

### Log-Datei prüfen
```bash
tail -f /var/log/vzdump-gpu-hook.log
```

### VMs werden nicht gestoppt
```bash
# Prüfe GPU-Zuordnung im Skript
grep "GPU_GROUPS\[" /usr/local/bin/backup-gpu-hook.sh

# Vergleiche mit tatsächlichen PCI-Adressen
lspci | grep VGA

# Prüfe VM-Konfigurationen
grep hostpci /etc/pve/qemu-server/*.conf
```

### Manuelle Tests
```bash
# Simuliere Backup-Job
/usr/local/bin/backup-gpu-hook.sh job-start test
/usr/local/bin/backup-gpu-backup-hook.sh backup-start 100
/usr/local/bin/backup-gpu-hook.sh backup-end 100
/usr/local/bin/backup-gpu-hook.sh job-end test

# Prüfe Log
cat /var/log/vzdump-gpu-hook.log
```

## 📝 Anforderungen

- Proxmox VE 7.x oder 8.x
- Root-Zugriff
- VMs mit GPU-Passthrough (hostpci)
- Bash 4.0+

## 🤝 Beitragen

Probleme oder Verbesserungen? Erstelle ein Issue oder Pull Request!

## 📜 Lizenz

MIT License - Frei verwendbar für private und kommerzielle Zwecke

## 💡 Credits

Entwickelt für die Proxmox-Community von Administratoren, die das gleiche Problem hatten.

---

**⭐ Wenn dieses Skript hilfreich war, gib dem Repo einen Star!**