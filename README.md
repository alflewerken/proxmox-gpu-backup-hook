# Proxmox GPU Backup Hook 🔧

🇬🇧 English | [🇩🇪 Deutsch](README.de.md)

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-7.x%20%7C%208.x-orange.svg)](https://www.proxmox.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-2.2-blue.svg)](CHANGELOG.md)
[![GitHub issues](https://img.shields.io/github/issues/alflewerken/proxmox-gpu-backup-hook)](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)

**Zero-configuration automatic backup solution for Proxmox VMs with GPU passthrough. Prevents backup failures caused by GPU conflicts. One-line installation - no manual configuration needed!**

> **"From a Proxmox admin for Proxmox admins"**
>
> After hours of failed backup jobs and manual VM juggling, I built this hook to automate what should have been automatic. Version 2.2 includes a critical fix for `--mode stop` backups that makes it production-ready!

## 🆕 What's New in Version 2.2

🔥 **CRITICAL FIX: VMID Parsing** - Fixed broken backup-start detection in `--mode stop` backups  
✨ **Production Ready** - Extensively tested with real-world Proxmox setups  
✨ **Zero-Configuration** - Automatic GPU detection, no manual setup needed  
✨ **Future-Proof** - Adapts automatically when you add/remove VMs  
✨ **Container Support** - Works with both VMs and LXC containers  

**The Problem (Fixed in v2.2):**
```bash
# Proxmox passes: backup-start stop 105
# v2.0-2.1: VMID=$2 → Got "stop" instead of "105" ❌
# v2.2:     VMID=$3 → Correctly gets "105" ✅
```

**Version 2.0 vs 2.2:**
```bash
# Version 2.0-2.1 (BROKEN with --mode stop):
VMID=$2  # Incorrectly captured "stop" as VMID

# Version 2.2 (FIXED):
if [[ "$2" =~ ^(stop|snapshot|suspend)$ ]]; then
    VMID=$3  # Correctly gets VMID after mode
else
    VMID=$2  # Backwards compatible with other modes
fi
```

**Impact:** Without this fix, the hook silently fails with `--mode stop`, which is the most common backup mode for GPU VMs!

---

## The Problem 🐛

Multiple Proxmox VMs cannot share a single physical GPU simultaneously. When backing up with `--mode stop`, Proxmox temporarily starts the VM, causing failures if another VM is already using the GPU:

```
ERROR: PCI device '0000:05:00.0' already in use by VMID '104'
ERROR: Backup of VM 102 failed - start failed: QEMU exited with code 1
```

**Real-world scenario:**
- VMs 102, 103, 104, 105 share RTX 3090 Ti (PCI 05:00)
- VM 104 is running → Backup of 102, 103, 105 fails
- Manual intervention required every night 😢

## The Solution ✅

This hook **automatically manages VM conflicts**:

1. **Before backup:** Detects which GPU the VM uses
2. **Stops conflicting VMs:** Safely stops other VMs using the same GPU
3. **Backs up the VM:** Backup proceeds without conflicts
4. **Restarts stopped VMs:** After all backups complete, restarts all stopped VMs

```
[2025-11-04 09:08:02] [backup-start] [VM 102] VM/CT 102 uses GPU 05:00
[2025-11-04 09:08:02] [backup-start] [VM 102] VMs/CTs with GPU 05:00: 102 103 104 105
[2025-11-04 09:08:03] [backup-start] [VM 102] Stopping VM/CT 104 (uses same GPU)
[2025-11-04 09:15:30] [backup-end] [VM 102] Backup completed
[2025-11-04 09:15:30] [job-end] Starting VM 104
```

---

## Features 🎯

- ✅ **Zero-Configuration** - Automatic GPU detection from VM configs
- ✅ **Dynamic Discovery** - Scans all VMs before each backup
- ✅ **Smart Conflict Resolution** - Only stops VMs that share the same GPU
- ✅ **State Management** - Remembers which VMs to restart
- ✅ **Multi-GPU Support** - Handles multiple different GPUs automatically
- ✅ **Container Support** - Works with both QEMU VMs and LXC containers
- ✅ **Production Tested** - Battle-tested with NVIDIA RTX 4090/3090 Ti setups
- ✅ **Comprehensive Logging** - Detailed logs in `/var/log/vzdump-gpu-hook.log`
- ✅ **One-Line Installation** - No manual configuration required

---

## Quick Start 🚀

### One-Line Installation

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

**That's it!** The script will:
1. Detect your GPUs and GPU-enabled VMs
2. Install the hook to `/usr/local/bin/backup-gpu-hook.sh`
3. Configure `/etc/vzdump.conf`
4. Set up log rotation
5. Show you exactly which VMs were detected

### Manual Installation

```bash
# Download hook script
wget -O /usr/local/bin/backup-gpu-hook.sh \
  https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh
chmod +x /usr/local/bin/backup-gpu-hook.sh

# Add to vzdump.conf
cat >> /etc/vzdump.conf << 'EOF'

# GPU-Passthrough Backup Hook
script: /usr/local/bin/backup-gpu-hook.sh
mode: stop
ionice: 7
EOF

# Set up log rotation
cat > /etc/logrotate.d/vzdump-gpu-hook << 'EOF'
/var/log/vzdump-gpu-hook.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
```

---

## Configuration 📝

### No Configuration Needed! 🎉

Version 2.2 requires **zero manual configuration**. The script automatically:
- Scans `/etc/pve/qemu-server/*.conf` for VM GPU assignments
- Scans `/etc/pve/lxc/*.conf` for container GPU assignments  
- Detects GPU conflicts before each backup
- Groups VMs dynamically based on their current GPU assignment

### vzdump.conf Settings

The installation automatically adds these recommended settings:

```conf
# GPU-Passthrough Backup Hook
script: /usr/local/bin/backup-gpu-hook.sh

# Backup mode (stop required for GPU VMs)
mode: stop

# Low I/O priority (0-7, 7=lowest)
ionice: 7
```

**Optional settings:**
```conf
# Retention policy
prune-backups: keep-daily=10,keep-last=10,keep-monthly=4

# Email notifications
mailto: admin@example.com

# Default storage
storage: pbs-ptest
```

---

## How It Works 🔍

### Hook Phases

Proxmox calls the hook at different backup stages:

| Phase | When | Action |
|-------|------|--------|
| `job-init` | Before job | Initialization |
| `job-start` | Job begins | Clear state file |
| `backup-start` | Before each VM | **Stop conflicting VMs** |
| `backup-end` | After each VM | Log completion |
| `backup-abort` | On error | Cleanup |
| `job-end` | Job complete | **Restart stopped VMs** |

### GPU Detection Logic

```bash
# 1. Extract GPU from VM config
get_vm_gpu() {
    # Reads: hostpci0: 0000:05:00,pcie=1,x-vga=1
    # Returns: 05:00
}

# 2. Find all VMs with same GPU
find_all_vms_with_gpu() {
    # Scans all /etc/pve/qemu-server/*.conf
    # Returns: 102 103 104 105
}

# 3. Stop conflicting VMs
stop_conflicting_vms() {
    # Stops all except current VM
    # Saves PIDs to state file
}

# 4. Restart stopped VMs
restart_stopped_vms() {
    # Reads state file
    # Starts all saved VMs
}
```

---

## Testing 🧪

### Verify Installation

```bash
# Check if hook is configured
grep "^script:" /etc/vzdump.conf

# Check script permissions
ls -la /usr/local/bin/backup-gpu-hook.sh

# Test hook manually
/usr/local/bin/backup-gpu-hook.sh backup-start stop 102

# Check logs
tail -20 /var/log/vzdump-gpu-hook.log
```

### Test Backup

```bash
# Backup single VM
vzdump 102 --storage pbs-ptest --mode stop --notes-template 'Test Backup'

# Check if conflicting VMs were stopped and restarted
tail -50 /var/log/vzdump-gpu-hook.log
```

**Expected log output:**
```log
[2025-11-04 09:08:02] [job-start] === Backup job starting ===
[2025-11-04 09:08:02] [backup-start] [VM 102] VM/CT 102 uses GPU 05:00
[2025-11-04 09:08:02] [backup-start] [VM 102] VMs/CTs with GPU 05:00: 102 103 104 105
[2025-11-04 09:08:03] [backup-start] [VM 102] Stopping VM/CT 104
[2025-11-04 09:15:30] [backup-end] [VM 102] Backup completed
[2025-11-04 09:15:30] [job-end] === Backup job completed ===
[2025-11-04 09:15:30] [job-end] Restarting stopped VMs/Containers
[2025-11-04 09:15:30] [job-end] Starting VM 104
```

---

## Troubleshooting 🔧

### Hook not being called

**Symptoms:**
- No entries in `/var/log/vzdump-gpu-hook.log`
- VMs not being stopped

**Solution:**
```bash
# Verify hook is configured
grep "^script:" /etc/vzdump.conf

# Check permissions
chmod +x /usr/local/bin/backup-gpu-hook.sh

# Test manually
/usr/local/bin/backup-gpu-hook.sh job-start test
cat /var/log/vzdump-gpu-hook.log
```

### VMID shows as "stop" (Version 2.0-2.1 bug)
**Symptoms:**
```log
[backup-start] [VM stop] VM/CT stop has no GPU-Passthrough configuration
```

**Cause:** Old hook version before v2.2 bugfix

**Solution:**
```bash
# Update to version 2.2
cd /usr/local/bin
mv backup-gpu-hook.sh backup-gpu-hook.sh.old
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh
chmod +x backup-gpu-hook.sh
```

### VMs not restarting after backup

**Symptoms:**
- VMs remain stopped after backup
- State file still exists: `/tmp/vzdump-gpu-stopped-vms.state`

**Solution:**
```bash
# Check state file
cat /tmp/vzdump-gpu-stopped-vms.state

# Manually restart VMs
for vm in $(cat /tmp/vzdump-gpu-stopped-vms.state); do
    qm start $vm
done

# Cleanup
rm -f /tmp/vzdump-gpu-stopped-vms.state
```

### GPU in D3cold Power State

**Symptoms:**
```
error writing '1' to '/sys/bus/pci/devices/0000:05:00.0/reset'
kvm: pci_irq_handler: Assertion failed
Unable to change power state from D3cold to D0
```

**Diagnosis:**
```bash
# Check GPU status
lspci -D | grep -i nvidia
dmesg | tail -20

# Check power state
cat /sys/bus/pci/devices/0000:05:00.1/power_state
```

**Solution:**
```bash
# Only reliable solution for D3cold
reboot
```

---

## Supported Hardware 💻

### Tested GPUs

- ✅ NVIDIA RTX 4090
- ✅ NVIDIA RTX 3090 Ti
- ✅ NVIDIA RTX 3080
- ✅ Intel UHD Graphics 770 (SR-IOV)
- ✅ AMD Radeon RX 6800 XT

### Tested Proxmox Versions

- ✅ Proxmox VE 8.x
- ✅ Proxmox VE 7.x
- ✅ Proxmox Backup Server (PBS)

---

## Advanced Usage 🎓

### Multiple GPU Groups

The script automatically handles multiple different GPUs:

```bash
# RTX 4090 at 01:00
VMs 100, 101, 102 → GPU 01:00.0

# RTX 3090 Ti at 05:00
VMs 103, 104, 105 → GPU 05:00.0

# Intel UHD at 00:02.1
VMs 200, 201 → GPU 00:02.1
```

No configuration needed - the script detects and groups automatically!

### Scheduled Backups

In Proxmox WebUI: **Datacenter → Backup → Add**

```
Schedule: 02:00
Mode: stop (already configured in vzdump.conf)
Storage: pbs-ptest
Selection: All
Exclude: 100 (non-GPU VMs)
Prune: keep-daily=10,keep-last=10,keep-monthly=4
Notes: {{guestname}}
```

### Monitoring

```bash
# Watch logs in real-time
tail -f /var/log/vzdump-gpu-hook.log

# Check for errors
grep "ERROR\|ABORT" /var/log/vzdump-gpu-hook.log

# Daily error check (cron)
0 8 * * * grep "ERROR\|ABORT" /var/log/vzdump-gpu-hook.log && \
          mail -s "Backup Errors" admin@example.com
```

---

## Migration Guide 📦

### From Version 1.x to 2.2

**Version 1.x (Manual configuration):**
```bash
# Old: Manual GPU groups
declare -A GPU_GROUPS
GPU_GROUPS["05:00"]="102 103 104 105"
GPU_GROUPS["01:00"]="100 101"
```

**Version 2.2 (Automatic):**
```bash
# New: Zero configuration!
# Script auto-detects all GPU assignments
```

**Migration steps:**
1. Backup old script: `cp /usr/local/bin/backup-gpu-hook.sh{,.v1-backup}`
2. Download v2.2: `wget -O /usr/local/bin/backup-gpu-hook.sh https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh`
3. Make executable: `chmod +x /usr/local/bin/backup-gpu-hook.sh`
4. Test: `vzdump 102 --storage pbs-ptest --mode stop`
5. Verify logs: `tail -20 /var/log/vzdump-gpu-hook.log`

### From Version 2.0-2.1 to 2.2

**Critical fix:** VMID parsing for `--mode stop`

Simply update the script:
```bash
cd /usr/local/bin
mv backup-gpu-hook.sh backup-gpu-hook.sh.v2.0
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh
chmod +x backup-gpu-hook.sh
```

---

## FAQ ❓

### Does this work with snapshot backups?

**No.** Proxmox cannot create snapshots of VMs with PCI passthrough. The `mode: stop` setting is required for GPU VMs.

### What happens if the script crashes during backup?

The state file (`/tmp/vzdump-gpu-stopped-vms.state`) persists. VMs must be manually restarted:
```bash
for vm in $(cat /tmp/vzdump-gpu-stopped-vms.state); do qm start $vm; done
```

### Can I exclude specific VMs from the hook?

Yes, use `--exclude` in your backup job or vzdump.conf:
```bash
vzdump --all 1 --exclude 100,200 --storage pbs-ptest
```

### Does this support Intel SR-IOV?

Yes! The script detects all PCI devices, including Intel UHD Graphics Virtual Functions (VFs).

### How long does stopping/starting VMs take?

Typical timings:
- VM Stop: 2-5 seconds
- VM Start: 5-15 seconds
- Hook Overhead: <1 second per VM

---

## Best Practices 🏆

### 1. Backup Windows

- Schedule backups at night (02:00-06:00)
- Stagger GPU VM backups from non-GPU VMs
- Example:
  - 02:00 → GPU VMs
  - 03:00 → Regular VMs

### 2. Retention Policies

```conf
# Production VMs
prune-backups: keep-daily=10,keep-weekly=4,keep-monthly=6,keep-yearly=2

# Dev/Test VMs
prune-backups: keep-daily=7,keep-last=7,keep-monthly=3
```

### 3. Monitoring

```bash
# Daily check for backup errors
cat > /etc/cron.daily/check-backup-errors << 'EOF'
#!/bin/bash
ERRORS=$(grep -c "ERROR\|ABORT" /var/log/vzdump-gpu-hook.log)
if [ $ERRORS -gt 0 ]; then
    tail -50 /var/log/vzdump-gpu-hook.log | \
    mail -s "Backup Errors: $ERRORS found" admin@example.com
fi
EOF
chmod +x /etc/cron.daily/check-backup-errors
```

### 4. Testing Strategy

**Phase 1 - Single VM:**
```bash
vzdump 102 --storage pbs-ptest --mode stop
```

**Phase 2 - All GPU VMs:**
```bash
vzdump 102 103 104 105 --storage pbs-ptest --mode stop
```

**Phase 3 - Recovery Test:**
```bash
qmrestore pbs-ptest:backup-vm-102-2025_11_04.vma.zst 999 --storage local-btrfs
qm start 999
```

**Phase 4 - Automation:**
- Enable scheduled backup
- Monitor logs for first week
- Verify restore periodically

---

## Performance Tips ⚡

### I/O Throttling

```conf
# In vzdump.conf
ionice: 7          # Lowest I/O priority
bwlimit: 50000     # Bandwidth limit in KB/s (optional)
```

### Parallel Backups

⚠️ **Not recommended for GPU VMs!** Only one VM per GPU can run at a time.

For non-GPU VMs:
```conf
performance: max-workers=4,pbs-entries-max=256
```

---

## Contributing 🤝

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Reporting Bugs

Please include:
1. Proxmox version: `pveversion`
2. Hook version: `head -15 /usr/local/bin/backup-gpu-hook.sh`
3. VM configs: `cat /etc/pve/qemu-server/XXX.conf`
4. Logs: `tail -50 /var/log/vzdump-gpu-hook.log`
5. GPU info: `lspci | grep -i vga`

---

## Changelog 📋

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

### Quick Summary

- **v2.2 (2025-11-04)** - Critical fix: VMID parsing for `--mode stop`
- **v2.1 (2025-10-30)** - Improved abort handling, container support
- **v2.0 (2025-10-26)** - Dynamic GPU detection, zero configuration
- **v1.0 (2025-10-01)** - Initial release with manual GPU groups

---

## License 📄

MIT License - see [LICENSE](LICENSE) for details

Copyright (c) 2025 Alf Lewerken

---

## Support ⭐

If this project helped you, please consider:

- ⭐ Starring the repository
- 🐛 Reporting bugs and suggesting features
- 📖 Improving documentation
- 💬 Sharing your experience in discussions

---

## Credits 🙏

**Author:** Alf Lewerken

**Tested with:**
- Multiple NVIDIA RTX 4090/3090 Ti setups
- Intel UHD Graphics SR-IOV configurations
- Proxmox VE 8.x clusters
- Real-world production environments

**Special thanks:**
- Proxmox VE Community
- Claude AI (Anthropic) for debugging assistance
- Beta testers from the Proxmox forums

---

## Links 🔗

- **GitHub:** https://github.com/alflewerken/proxmox-gpu-backup-hook
- **Issues:** https://github.com/alflewerken/proxmox-gpu-backup-hook/issues
- **Discussions:** https://github.com/alflewerken/proxmox-gpu-backup-hook/discussions
- **Proxmox Forum:** https://forum.proxmox.com/

---

**Made with ❤️ by a Proxmox admin, for Proxmox admins**
