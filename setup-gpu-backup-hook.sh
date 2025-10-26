#!/bin/bash
#
# Proxmox GPU Backup Hook - Automatische Installation
# Für Server mit GPU-Passthrough VMs
#
# Löst das Problem: VMs mit geteilten GPUs können nicht gleichzeitig laufen
# und werden beim Backup übersprungen.
#
# Installation:
#   wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/setup-gpu-backup-hook.sh
#   chmod +x setup-gpu-backup-hook.sh
#   ./setup-gpu-backup-hook.sh
#
# Oder direkt:
#   curl -sL [URL] | bash
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

HOOK_SCRIPT="/usr/local/bin/backup-gpu-hook.sh"
VZDUMP_CONF="/etc/vzdump.conf"
LOGFILE="/var/log/vzdump-gpu-hook.log"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Proxmox GPU Backup Hook Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Prüfe ob Proxmox VE
if [ ! -d "/etc/pve" ]; then
    echo -e "${RED}FEHLER: Dies ist kein Proxmox VE System!${NC}"
    exit 1
fi

echo -e "${GREEN}[1/6]${NC} Erkenne GPUs..."
echo "---------------------------------------"
if ! lspci | grep -E 'VGA|3D|Display' > /dev/null; then
    echo -e "${YELLOW}⚠ Keine GPUs gefunden${NC}"
else
    lspci | grep -E 'VGA|3D|Display'
fi
echo ""

echo -e "${GREEN}[2/6]${NC} Suche VMs mit GPU-Passthrough..."
echo "---------------------------------------"
gpu_vms_found=false

# Prüfe VMs (qemu)
for vm in /etc/pve/qemu-server/*.conf 2>/dev/null; do
    if [ -f "$vm" ] && grep -q '^hostpci' "$vm" 2>/dev/null; then
        vmid=$(basename "$vm" .conf)
        gpu=$(grep '^hostpci' "$vm" | head -1 | sed -n 's/.*hostpci[0-9]*: \([0-9a-f:\.]*\).*/\1/p' | sed 's/^0000://')
        name=$(grep '^name:' "$vm" | cut -d' ' -f2 2>/dev/null || echo "N/A")
        echo "VM $vmid ($name): GPU $gpu"
        gpu_vms_found=true
    fi
done

# Prüfe Container (lxc)
for ct in /etc/pve/lxc/*.conf 2>/dev/null; do
    if [ -f "$ct" ] && grep -q 'lxc.cgroup2.devices.allow' "$ct" 2>/dev/null; then
        ctid=$(basename "$ct" .conf)
        name=$(grep '^hostname:' "$ct" | cut -d' ' -f2 2>/dev/null || echo "N/A")
        echo "CT $ctid ($name): hat GPU-Zugriff"
        gpu_vms_found=true
    fi
done

if [ "$gpu_vms_found" = false ]; then
    echo -e "${YELLOW}⚠ Keine VMs/Container mit GPU-Passthrough gefunden${NC}"
    echo "  Hook-Skript wird trotzdem installiert."
fi
echo ""

echo -e "${GREEN}[3/6]${NC} Erstelle Hook-Skript..."
echo "---------------------------------------"
# Erstelle Hook-Skript direkt im Setup
cat > "$HOOK_SCRIPT" << 'HOOKSCRIPT'
#!/bin/bash
#
# Proxmox Backup Hook für GPU-Passthrough VMs
# Stoppt konkurrierende VMs mit derselben GPU vor dem Backup
# und startet sie nach dem Backup-Job wieder
#
# Generiert von: setup-gpu-backup-hook.sh
#

PHASE=$1
VMID=$2
LOGFILE="/var/log/vzdump-gpu-hook.log"
STATEFILE="/tmp/vzdump-gpu-stopped-vms.state"

# ============================================================
# GPU-ZUORDNUNG - HIER ANPASSEN!
# ============================================================
# Format: GPU_GROUPS["PCI-Adresse"]="VM1 VM2 VM3"
# PCI-Adresse OHNE "0000:" Präfix (z.B. "01:00.0" statt "0000:01:00.0")
#
# Beispiele:
# GPU_GROUPS["01:00.0"]="104 106 107 116"  # RTX 4090
# GPU_GROUPS["05:00.0"]="105 112"          # RTX 3090 Ti
# GPU_GROUPS["00:02.1"]="201"              # Intel UHD VF
#
declare -A GPU_GROUPS

# TODO: Trage hier deine GPU-Zuordnungen ein:
# GPU_GROUPS["XX:XX.X"]="VM-IDs"  # GPU-Beschreibung

# ============================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$PHASE] [VM $VMID] $1" >> "$LOGFILE"
}

get_vm_gpu() {
    local vmid=$1
    # Prüfe zuerst qemu-server (VMs)
    local gpu=$(grep "^hostpci" /etc/pve/qemu-server/${vmid}.conf 2>/dev/null | \
                head -1 | \
                sed -n 's/.*hostpci[0-9]*: \([0-9a-f:\.]*\).*/\1/p' | \
                sed 's/^0000://')
    
    # Falls leer, prüfe lxc (Container)
    if [ -z "$gpu" ]; then
        gpu=$(grep "^lxc.cgroup2.devices.allow" /etc/pve/lxc/${vmid}.conf 2>/dev/null | \
              head -1 | \
              grep -oP '([0-9a-f]{2}:){2}[0-9a-f]{2}\.[0-9]')
    fi
    
    echo "$gpu"
}

is_vm_running() {
    local vmid=$1
    # Prüfe ob es eine VM ist
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        qm status $vmid 2>/dev/null | grep -q "running"
        return $?
    fi
    # Prüfe ob es ein Container ist
    if [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        pct status $vmid 2>/dev/null | grep -q "running"
        return $?
    fi
    return 1
}

stop_vm() {
    local vmid=$1
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        qm stop $vmid
    elif [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        pct stop $vmid
    fi
}

start_vm() {
    local vmid=$1
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        log "Starte VM $vmid wieder"
        qm start $vmid
    elif [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        log "Starte Container $vmid wieder"
        pct start $vmid
    fi
}

stop_conflicting_vms() {
    local current_vm=$1
    local current_gpu=$(get_vm_gpu $current_vm)
    
    if [ -z "$current_gpu" ]; then
        log "VM/CT $current_vm hat keine GPU-Passthrough-Konfiguration"
        return 0
    fi
    
    log "VM/CT $current_vm nutzt GPU $current_gpu"
    
    # Finde alle VMs, die dieselbe GPU nutzen
    for check_gpu in "${!GPU_GROUPS[@]}"; do
        if [[ "$current_gpu" == "$check_gpu" ]]; then
            log "GPU-Gruppe gefunden: ${GPU_GROUPS[$check_gpu]}"
            
            for vm in ${GPU_GROUPS[$check_gpu]}; do
                if [ "$vm" == "$current_vm" ]; then
                    continue
                fi
                
                # Prüfe ob VM/Container läuft
                if is_vm_running $vm; then
                    log "Stoppe VM/CT $vm (nutzt dieselbe GPU $check_gpu)"
                    # Merke, dass diese VM ursprünglich lief
                    echo "$vm" >> "$STATEFILE"
                    stop_vm $vm
                    sleep 2
                fi
            done
        fi
    done
}

restart_stopped_vms() {
    if [ ! -f "$STATEFILE" ]; then
        log "Keine gestoppten VMs zum Neustarten"
        return 0
    fi
    
    log "Starte gestoppte VMs/Container wieder"
    
    # Lese alle gestoppten VMs und starte sie
    while IFS= read -r vmid; do
        if [ -n "$vmid" ]; then
            start_vm $vmid
            sleep 1
        fi
    done < "$STATEFILE"
    
    # Lösche State-Datei
    rm -f "$STATEFILE"
    log "Alle gestoppten VMs/Container wurden neu gestartet"
}

case "$PHASE" in
    job-start)
        log "=== Backup-Job startet ==="
        # Lösche alte State-Datei falls vorhanden
        rm -f "$STATEFILE"
        ;;
        
    backup-start)
        log "Backup startet für VM/CT $VMID"
        stop_conflicting_vms $VMID
        ;;
        
    backup-end)
        log "Backup beendet für VM/CT $VMID"
        ;;
        
    job-end)
        log "=== Backup-Job abgeschlossen ==="
        restart_stopped_vms
        ;;
        
    *)
        log "Unbekannte Phase: $PHASE"
        ;;
esac

exit 0
HOOKSCRIPT

chmod +x "$HOOK_SCRIPT"
echo -e "${GREEN}✓${NC} Hook-Skript erstellt: $HOOK_SCRIPT"
echo ""
echo -e "${GREEN}[4/6]${NC} Konfiguriere vzdump.conf..."
echo "---------------------------------------"

# Erstelle Backup der vzdump.conf
if [ -f "$VZDUMP_CONF" ]; then
    cp "$VZDUMP_CONF" "${VZDUMP_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓${NC} Backup erstellt: ${VZDUMP_CONF}.backup-*"
fi

# Prüfe ob Hook bereits konfiguriert ist
if grep -q "^script:.*backup-gpu-hook.sh" "$VZDUMP_CONF" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Hook-Skript bereits in vzdump.conf konfiguriert"
else
    cat >> "$VZDUMP_CONF" << 'EOF'

# ============================================================
# GPU-Passthrough Backup Hook
# Generiert von: setup-gpu-backup-hook.sh
# ============================================================
script: /usr/local/bin/backup-gpu-hook.sh
mode: stop
ionice: 7
EOF
    echo -e "${GREEN}✓${NC} vzdump.conf aktualisiert"
fi
echo ""

echo -e "${GREEN}[5/6]${NC} Erstelle Logrotation..."
echo "---------------------------------------"
cat > /etc/logrotate.d/vzdump-gpu-hook << 'EOF'
/var/log/vzdump-gpu-hook.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
echo -e "${GREEN}✓${NC} Logrotation konfiguriert"
echo ""

echo -e "${GREEN}[6/6]${NC} Erstelle Beispiel-Konfiguration..."
echo "---------------------------------------"

# Sammle GPU-Informationen für Beispiel
example_config="/tmp/gpu-backup-example.txt"
cat > "$example_config" << 'EOF'
# ============================================================
# BEISPIEL GPU-ZUORDNUNGEN FÜR DEIN SYSTEM
# ============================================================
# Kopiere diese Zeilen in /usr/local/bin/backup-gpu-hook.sh
# und passe sie an deine VMs an.
#

declare -A GPU_GROUPS

EOF

# Erstelle automatisch Vorschläge basierend auf gefundenen VMs
echo "# Gefundene GPU-Konfigurationen:" >> "$example_config"
echo "#" >> "$example_config"

declare -A gpu_to_vms

for vm in /etc/pve/qemu-server/*.conf 2>/dev/null; do
    if [ -f "$vm" ] && grep -q '^hostpci' "$vm" 2>/dev/null; then
        vmid=$(basename "$vm" .conf)
        gpu=$(grep '^hostpci' "$vm" | head -1 | sed -n 's/.*hostpci[0-9]*: \([0-9a-f:\.]*\).*/\1/p' | sed 's/^0000://')
        if [ -n "$gpu" ]; then
            if [ -z "${gpu_to_vms[$gpu]}" ]; then
                gpu_to_vms[$gpu]="$vmid"
            else
                gpu_to_vms[$gpu]="${gpu_to_vms[$gpu]} $vmid"
            fi
        fi
    fi
done

for gpu in "${!gpu_to_vms[@]}"; do
    gpu_model=$(lspci -s "0000:$gpu" 2>/dev/null | grep -oP ':\s+\K.*' || echo "Unknown GPU")
    echo "GPU_GROUPS[\"$gpu\"]=\"${gpu_to_vms[$gpu]}\"  # $gpu_model" >> "$example_config"
done

if [ ${#gpu_to_vms[@]} -eq 0 ]; then
    cat >> "$example_config" << 'EOF'
# Keine VMs mit GPU-Passthrough automatisch erkannt.
# Beispiel-Konfiguration:
#
# GPU_GROUPS["01:00.0"]="100 101 102"  # NVIDIA RTX 4090
# GPU_GROUPS["05:00.0"]="110 111"      # NVIDIA RTX 3090 Ti
# GPU_GROUPS["00:02.1"]="200"          # Intel UHD Graphics VF
EOF
fi

cat >> "$example_config" << 'EOF'

# ============================================================
# SO TRÄGST DU DIE KONFIGURATION EIN:
# ============================================================
# 1. Öffne das Hook-Skript:
#    nano /usr/local/bin/backup-gpu-hook.sh
#
# 2. Finde die Zeilen mit "TODO: Trage hier deine GPU-Zuordnungen ein"
#    (ungefähr bei Zeile 23-26)
#
# 3. Ersetze die TODO-Zeile durch deine GPU_GROUPS Definitionen
#    (siehe oben die automatisch erkannten Vorschläge)
#
# 4. Speichern und Skript testen:
#    /usr/local/bin/backup-gpu-hook.sh job-start test
#    cat /var/log/vzdump-gpu-hook.log
#
# ============================================================
EOF

cat "$example_config"
echo ""
echo -e "${GREEN}✓${NC} Beispiel-Konfiguration gespeichert: $example_config"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Installation abgeschlossen!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}WICHTIG - NÄCHSTE SCHRITTE:${NC}"
echo ""
echo "1. GPU-Zuordnungen konfigurieren:"
echo "   nano $HOOK_SCRIPT"
echo "   (Suche nach 'TODO' und trage deine VMs ein)"
echo ""
echo "2. Beispiel-Konfiguration ansehen:"
echo "   cat $example_config"
echo ""
echo "3. Hook-Skript testen:"
echo "   $HOOK_SCRIPT job-start test"
echo "   cat $LOGFILE"
echo ""
echo "4. Backup-Job in Proxmox WebUI erstellen:"
echo "   Datacenter → Backup → Add"
echo "   - Schedule: z.B. 02:00"
echo "   - Mode: stop (bereits konfiguriert)"
echo "   - Storage: Dein Backup-Storage"
echo ""
echo -e "${GREEN}Dokumentation und Updates:${NC}"
echo "https://github.com/alflewerken/proxmox-gpu-backup-hook/proxmox-gpu-backup-hook"
echo ""
