#!/bin/bash
#
# Proxmox GPU Backup Hook - Automatic Installation (Version 2.4.0)
# For servers with GPU-Passthrough VMs
#
# Solves the problem: VMs with shared GPUs cannot run simultaneously
# and are skipped during backup.
#
# NEW in Version 2.4:
# - CRITICAL FIX: Race condition causing VMs not to restart after backup
# - CRITICAL FIX: VMs now restart even after backup-abort/failure
# - Works reliably without qemu-guest-agent
# - Fully automatic GPU detection - NO manual configuration needed!
# - Dynamic VM scanning - adapts automatically to VM changes
# - Zero-configuration installation
#
# Installation:
#   wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
#   chmod +x setup-gpu-backup-hook.sh
#   ./setup-gpu-backup-hook.sh
#
# Or directly:
#   curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOOK_SCRIPT="/usr/local/bin/backup-gpu-hook.sh"
VZDUMP_CONF="/etc/vzdump.conf"
LOGFILE="/var/log/vzdump-gpu-hook.log"
VERSION="2.4.0"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Proxmox GPU Backup Hook Setup v${VERSION}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}🎯 Zero-Configuration Installation${NC}"
echo -e "${BLUE}   Dynamic GPU detection - no manual setup needed!${NC}"
echo ""

# Check if Proxmox VE
if [ ! -d "/etc/pve" ]; then
    echo -e "${RED}ERROR: This is not a Proxmox VE system!${NC}"
    exit 1
fi

echo -e "${GREEN}[1/7]${NC} Detecting GPUs..."
echo "---------------------------------------"
gpu_count=0
if lspci | grep -E 'VGA|3D|Display' > /dev/null; then
    lspci | grep -E 'VGA|3D|Display' | while read -r line; do
        echo "  🎮 $line"
        gpu_count=$((gpu_count + 1))
    done
    echo ""
    echo -e "${GREEN}✓${NC} Found GPUs in system"
else
    echo -e "${YELLOW}⚠ No GPUs detected${NC}"
    echo "  Hook will still be installed for future use"
fi
echo ""

echo -e "${GREEN}[2/7]${NC} Scanning VMs with GPU-Passthrough..."
echo "---------------------------------------"
gpu_vms_found=false
vm_count=0
ct_count=0

# Check VMs (qemu)
for vm in /etc/pve/qemu-server/*.conf; do
    [ -f "$vm" ] || continue
    if grep -q '^hostpci' "$vm" 2>/dev/null; then
        vmid=$(basename "$vm" .conf)
        gpu=$(grep '^hostpci' "$vm" | head -1 | sed -n 's/.*hostpci[0-9]*:[[:space:]]*\([0-9a-fA-F:\\.]*\).*/\1/p' | sed 's/^0000://')
        name=$(grep '^name:' "$vm" | cut -d' ' -f2 2>/dev/null || echo "unnamed")
        echo "  📦 VM $vmid ($name): GPU $gpu"
        gpu_vms_found=true
        vm_count=$((vm_count + 1))
    fi
done

# Check Containers (lxc)
for ct in /etc/pve/lxc/*.conf; do
    [ -f "$ct" ] || continue
    if grep -q 'lxc.cgroup2.devices.allow' "$ct" 2>/dev/null; then
        ctid=$(basename "$ct" .conf)
        name=$(grep '^hostname:' "$ct" | cut -d' ' -f2 2>/dev/null || echo "unnamed")
        echo "  📦 CT $ctid ($name): has GPU access"
        gpu_vms_found=true
        ct_count=$((ct_count + 1))
    fi
done

if [ "$gpu_vms_found" = false ]; then
    echo -e "${YELLOW}⚠ No VMs/Containers with GPU-Passthrough found${NC}"
    echo "  Hook will be installed and ready when you add GPU VMs"
else
    echo ""
    echo -e "${GREEN}✓${NC} Found $vm_count VMs and $ct_count Containers with GPU passthrough"
    echo -e "${BLUE}  These will be automatically managed by the hook!${NC}"
fi
echo ""

echo -e "${GREEN}[3/7]${NC} Downloading hook script..."
echo "---------------------------------------"
# Download from GitHub or use local file
SCRIPT_URL="https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh"

if command -v wget &> /dev/null; then
    if wget -q -O "$HOOK_SCRIPT" "$SCRIPT_URL" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Hook script downloaded successfully"
    else
        echo -e "${YELLOW}⚠${NC} Download failed, using embedded script"
        # Fallback: Embed script directly
        cat > "$HOOK_SCRIPT" << 'EMBEDDED_SCRIPT'
#!/bin/bash
# Embedded backup-gpu-hook.sh v2.0
# See: https://github.com/alflewerken/proxmox-gpu-backup-hook

PHASE=$1
VMID=$2
LOGFILE="/var/log/vzdump-gpu-hook.log"
STATEFILE="/tmp/vzdump-gpu-stopped-vms.state"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$PHASE] [VM $VMID] $1" >> "$LOGFILE"
}

get_vm_gpu() {
    local vmid=$1
    local gpu=""
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        gpu=$(grep "^hostpci" /etc/pve/qemu-server/${vmid}.conf 2>/dev/null | head -1 | sed -n 's/.*hostpci[0-9]*:[[:space:]]*\([0-9a-fA-F:\\.]*\).*/\1/p' | sed 's/^0000://')
    fi
    if [ -z "$gpu" ] && [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        gpu=$(grep "^lxc.cgroup2.devices.allow" /etc/pve/lxc/${vmid}.conf 2>/dev/null | head -1 | grep -oP '([0-9a-fA-F]{2}:){2}[0-9a-fA-F]{2}\.[0-9]')
    fi
    echo "$gpu"
}

find_all_vms_with_gpu() {
    local target_gpu=$1
    local vms=()
    for conf in /etc/pve/qemu-server/*.conf; do
        [ -f "$conf" ] || continue
        local vmid=$(basename "$conf" .conf)
        local vm_gpu=$(get_vm_gpu "$vmid")
        if [ -n "$vm_gpu" ] && [ "$vm_gpu" = "$target_gpu" ]; then
            vms+=("$vmid")
        fi
    done
    for conf in /etc/pve/lxc/*.conf; do
        [ -f "$conf" ] || continue
        local ctid=$(basename "$conf" .conf)
        local ct_gpu=$(get_vm_gpu "$ctid")
        if [ -n "$ct_gpu" ] && [ "$ct_gpu" = "$target_gpu" ]; then
            vms+=("$ctid")
        fi
    done
    echo "${vms[@]}"
}

is_vm_running() {
    local vmid=$1
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        qm status $vmid 2>/dev/null | grep -q "running"
        return $?
    fi
    if [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        pct status $vmid 2>/dev/null | grep -q "running"
        return $?
    fi
    return 1
}

stop_vm() {
    local vmid=$1
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        log "Stopping VM $vmid"
        qm stop $vmid 2>&1 | head -5 >> "$LOGFILE"
    elif [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        log "Stopping Container $vmid"
        pct stop $vmid 2>&1 | head -5 >> "$LOGFILE"
    fi
}

start_vm() {
    local vmid=$1
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        log "Starting VM $vmid"
        qm start $vmid 2>&1 | head -5 >> "$LOGFILE"
    elif [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        log "Starting Container $vmid"
        pct start $vmid 2>&1 | head -5 >> "$LOGFILE"
    fi
}

stop_conflicting_vms() {
    local current_vm=$1
    local current_gpu=$(get_vm_gpu $current_vm)
    if [ -z "$current_gpu" ]; then
        log "VM/CT $current_vm has no GPU-Passthrough configuration"
        return 0
    fi
    log "VM/CT $current_vm uses GPU $current_gpu"
    local conflicting_vms=$(find_all_vms_with_gpu "$current_gpu")
    if [ -z "$conflicting_vms" ]; then
        log "No other VMs/CTs with GPU $current_gpu found"
        return 0
    fi
    log "VMs/CTs with GPU $current_gpu: $conflicting_vms"
    for vm in $conflicting_vms; do
        if [ "$vm" = "$current_vm" ]; then
            continue
        fi
        if is_vm_running $vm; then
            log "Stopping VM/CT $vm (uses same GPU $current_gpu)"
            echo "$vm" >> "$STATEFILE"
            stop_vm $vm
            sleep 2
        fi
    done
}

restart_stopped_vms() {
    if [ ! -f "$STATEFILE" ]; then
        log "No stopped VMs to restart"
        return 0
    fi
    log "Restarting stopped VMs/Containers"
    sort -u "$STATEFILE" | while IFS= read -r vmid; do
        if [ -n "$vmid" ]; then
            start_vm $vmid
            sleep 2
        fi
    done
    rm -f "$STATEFILE"
    log "All stopped VMs/Containers have been restarted"
}

case "$PHASE" in
    job-start)
        log "=== Backup job starting ==="
        rm -f "$STATEFILE"
        ;;
    backup-start)
        log "Backup starting for VM/CT $VMID"
        stop_conflicting_vms $VMID
        ;;
    backup-end)
        log "Backup completed for VM/CT $VMID"
        ;;
    job-end)
        log "=== Backup job completed ==="
        restart_stopped_vms
        ;;
    *)
        log "Unknown phase: $PHASE (ignored)"
        ;;
esac
exit 0
EMBEDDED_SCRIPT
    fi
elif command -v curl &> /dev/null; then
    if curl -sL -o "$HOOK_SCRIPT" "$SCRIPT_URL" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Hook script downloaded successfully"
    else
        echo -e "${RED}ERROR: Could not download script and no fallback available${NC}"
        exit 1
    fi
else
    echo -e "${RED}ERROR: Neither wget nor curl available${NC}"
    exit 1
fi

chmod +x "$HOOK_SCRIPT"
echo -e "${GREEN}✓${NC} Hook script installed: $HOOK_SCRIPT"
echo ""

echo -e "${GREEN}[4/7]${NC} Configuring vzdump.conf..."
echo "---------------------------------------"

# Create backup of vzdump.conf
if [ -f "$VZDUMP_CONF" ]; then
    backup_file="${VZDUMP_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$VZDUMP_CONF" "$backup_file"
    echo -e "${GREEN}✓${NC} Backup created: $backup_file"
fi

# Check if hook already configured
if grep -q "^script:.*backup-gpu-hook.sh" "$VZDUMP_CONF" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Hook script already configured in vzdump.conf"
else
    # Ensure vzdump.conf exists
    touch "$VZDUMP_CONF"
    
    cat >> "$VZDUMP_CONF" << 'EOF'

# ============================================================
# GPU-Passthrough Backup Hook (v2.0 - Dynamic)
# Automatically detects and manages GPU conflicts
# No manual configuration needed!
# ============================================================
script: /usr/local/bin/backup-gpu-hook.sh
mode: stop
ionice: 7
EOF
    echo -e "${GREEN}✓${NC} vzdump.conf updated with automatic GPU management"
fi
echo ""

echo -e "${GREEN}[5/7]${NC} Setting up log rotation..."
echo "---------------------------------------"
cat > /etc/logrotate.d/vzdump-gpu-hook << 'EOF'
/var/log/vzdump-gpu-hook.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0640 root root
}
EOF
echo -e "${GREEN}✓${NC} Log rotation configured (weekly, 4 weeks retention)"
echo ""

echo -e "${GREEN}[6/7]${NC} Testing hook installation..."
echo "---------------------------------------"

# Test hook execution
if "$HOOK_SCRIPT" job-start test-install 2>&1 | grep -q "job starting"; then
    echo -e "${GREEN}✓${NC} Hook script executes successfully"
    
    # Check if log was created
    if [ -f "$LOGFILE" ]; then
        echo -e "${GREEN}✓${NC} Log file created: $LOGFILE"
        echo ""
        echo "Recent log entries:"
        tail -3 "$LOGFILE" | sed 's/^/  /'
    fi
else
    echo -e "${YELLOW}⚠${NC} Hook test completed (check logs for details)"
fi
echo ""

echo -e "${GREEN}[7/7]${NC} Generating system summary..."
echo "---------------------------------------"

# Create summary file
summary_file="/tmp/gpu-backup-summary-$(date +%Y%m%d-%H%M%S).txt"
cat > "$summary_file" << EOF
# ============================================================
# Proxmox GPU Backup Hook - Installation Summary
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Version: ${VERSION} (Dynamic GPU Detection)
# ============================================================

## Installation Status
✅ Hook script installed: $HOOK_SCRIPT
✅ Configuration updated: $VZDUMP_CONF
✅ Log rotation configured: /etc/logrotate.d/vzdump-gpu-hook
✅ Log file: $LOGFILE

## GPU Detection Summary
EOF

if [ "$gpu_vms_found" = true ]; then
    echo "Status: Active - GPU VMs detected and will be managed automatically" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Detected VMs/Containers:" >> "$summary_file"
    
    for vm in /etc/pve/qemu-server/*.conf; do
        [ -f "$vm" ] || continue
        if grep -q '^hostpci' "$vm" 2>/dev/null; then
            vmid=$(basename "$vm" .conf)
            gpu=$(grep '^hostpci' "$vm" | head -1 | sed -n 's/.*hostpci[0-9]*:[[:space:]]*\([0-9a-fA-F:\\.]*\).*/\1/p' | sed 's/^0000://')
            name=$(grep '^name:' "$vm" | cut -d' ' -f2 2>/dev/null || echo "unnamed")
            echo "  - VM $vmid ($name): GPU $gpu" >> "$summary_file"
        fi
    done
    
    for ct in /etc/pve/lxc/*.conf; do
        [ -f "$ct" ] || continue
        if grep -q 'lxc.cgroup2.devices.allow' "$ct" 2>/dev/null; then
            ctid=$(basename "$ct" .conf)
            name=$(grep '^hostname:' "$ct" | cut -d' ' -f2 2>/dev/null || echo "unnamed")
            echo "  - CT $ctid ($name): has GPU access" >> "$summary_file"
        fi
    done
else
    echo "Status: Ready - No GPU VMs detected yet" >> "$summary_file"
    echo "The hook will automatically activate when you add GPU passthrough VMs" >> "$summary_file"
fi

cat >> "$summary_file" << 'EOF'

## How It Works (Zero Configuration!)
The hook script automatically:
1. Scans all VM/CT configurations before each backup
2. Identifies which VMs share the same GPU
3. Stops conflicting VMs temporarily during backup
4. Restarts all stopped VMs after backup completes

No manual GPU group configuration needed!

## Next Steps
1. Create a backup job in Proxmox WebUI:
   - Navigate to: Datacenter → Backup → Add
   - Schedule: e.g., 02:00 (2 AM)
   - Mode: stop (already configured)
   - Storage: Select your backup storage
   - VMs: Select VMs to backup

2. Monitor first backup:
   tail -f /var/log/vzdump-gpu-hook.log

3. Review backup logs in WebUI:
   Datacenter → Tasks

## Documentation
- GitHub: https://github.com/alflewerken/proxmox-gpu-backup-hook
- Issues: https://github.com/alflewerken/proxmox-gpu-backup-hook/issues

## Log Files
- Hook operations: /var/log/vzdump-gpu-hook.log
- Backup tasks: Datacenter → Tasks in WebUI

============================================================
EOF

cat "$summary_file"
echo ""
echo -e "${GREEN}✓${NC} Summary saved to: $summary_file"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}🎉 Version 2.0 Features:${NC}"
echo "  ✅ Fully automatic GPU detection"
echo "  ✅ Zero manual configuration required"
echo "  ✅ Dynamic VM scanning"
echo "  ✅ Adapts automatically to VM changes"
echo ""
echo -e "${YELLOW}📋 Quick Start:${NC}"
echo ""
echo "1. Create backup job in WebUI:"
echo "   ${BLUE}Datacenter → Backup → Add${NC}"
echo ""
echo "2. Monitor your first backup:"
echo "   ${BLUE}tail -f $LOGFILE${NC}"
echo ""
echo "3. That's it! The hook handles everything automatically."
echo ""
echo -e "${GREEN}Documentation:${NC}"
echo "https://github.com/alflewerken/proxmox-gpu-backup-hook"
echo ""
echo -e "${GREEN}Support:${NC}"
echo "⭐ Star the repo if this saved your backups!"
echo "🐛 Report issues on GitHub"
echo ""
