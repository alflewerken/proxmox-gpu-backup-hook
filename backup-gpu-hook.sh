#!/bin/bash
#
# Proxmox Backup Hook for GPU-Passthrough VMs (Dynamic Version 2.0)
# Automatically detects GPU assignments from VM/CT configurations
# Stops conflicting VMs with the same GPU before backup
# and restarts them after the backup job completes
#
# Installation:
# 1. Copy to /usr/local/bin/backup-gpu-hook.sh
# 2. chmod +x /usr/local/bin/backup-gpu-hook.sh
# 3. Add to /etc/vzdump.conf: script: /usr/local/bin/backup-gpu-hook.sh
#
# Version: 2.0 (Dynamic GPU Detection)
# Author: Alf Lewerken
# Repository: https://github.com/alflewerken/proxmox-gpu-backup-hook
#

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
    
    # Check qemu-server first (VMs)
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        gpu=$(grep "^hostpci" /etc/pve/qemu-server/${vmid}.conf 2>/dev/null | \
              head -1 | \
              sed -n 's/.*hostpci[0-9]*:[[:space:]]*\([0-9a-fA-F:\\.]*\).*/\1/p' | \
              sed 's/^0000://')
    fi
    
    # If empty, check lxc (Containers)
    if [ -z "$gpu" ] && [ -f "/etc/pve/lxc/${vmid}.conf" ]; then
        gpu=$(grep "^lxc.cgroup2.devices.allow" /etc/pve/lxc/${vmid}.conf 2>/dev/null | \
              head -1 | \
              grep -oP '([0-9a-fA-F]{2}:){2}[0-9a-fA-F]{2}\.[0-9]')
    fi
    
    echo "$gpu"
}

find_all_vms_with_gpu() {
    local target_gpu=$1
    local vms=()
    
    # Search all VMs
    for conf in /etc/pve/qemu-server/*.conf; do
        [ -f "$conf" ] || continue
        local vmid=$(basename "$conf" .conf)
        local vm_gpu=$(get_vm_gpu "$vmid")
        
        if [ -n "$vm_gpu" ] && [ "$vm_gpu" = "$target_gpu" ]; then
            vms+=("$vmid")
        fi
    done
    
    # Search all Containers
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
    
    # Check if it's a VM
    if [ -f "/etc/pve/qemu-server/${vmid}.conf" ]; then
        qm status $vmid 2>/dev/null | grep -q "running"
        return $?
    fi
    
    # Check if it's a Container
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
    
    # Dynamically find all VMs/CTs with the same GPU
    local conflicting_vms=$(find_all_vms_with_gpu "$current_gpu")
    
    if [ -z "$conflicting_vms" ]; then
        log "No other VMs/CTs with GPU $current_gpu found"
        return 0
    fi
    
    log "VMs/CTs with GPU $current_gpu: $conflicting_vms"
    
    # Stop all running VMs/CTs except the current one
    for vm in $conflicting_vms; do
        if [ "$vm" = "$current_vm" ]; then
            continue
        fi
        
        if is_vm_running $vm; then
            log "Stopping VM/CT $vm (uses same GPU $current_gpu)"
            # Remember that this VM was originally running
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
    
    # Read all stopped VMs and start them (without duplicates)
    sort -u "$STATEFILE" | while IFS= read -r vmid; do
        if [ -n "$vmid" ]; then
            start_vm $vmid
            sleep 2
        fi
    done
    
    # Delete state file
    rm -f "$STATEFILE"
    log "All stopped VMs/Containers have been restarted"
}

case "$PHASE" in
    job-start)
        log "=== Backup job starting ==="
        # Delete old state file if present
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
