# Changelog

All notable changes to the Proxmox GPU Backup Hook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.4.0] - 2025-11-10

### 🔥 Critical Fix - Race Condition & Backup-Abort Handling

This release fixes a critical race condition that prevented VMs from restarting after backup failures or aborts. **If you're using any previous version, upgrade immediately to prevent VMs from staying stopped after backup errors!**

### 🐛 Critical Fixes

- **CRITICAL: Fixed race condition in `record_original_state()`**
  - vzdump begins VM shutdown BEFORE hook's `backup-start` phase executes
  - Previous versions checked `is_vm_running()` which returned false (VM already shutting down)
  - Result: VMs not added to restart list, stayed stopped after backup
  - **Impact:** VMs without qemu-guest-agent or with backup timeouts never restarted automatically
  - **Symptoms:** Log missing `"VM/CT XXX is currently running - recording for restart"` line
  
- **CRITICAL: Fixed missing VM restart after `backup-abort`**
  - When backups failed/aborted, VMs were not added to restart list
  - Previous versions did nothing in `backup-abort` phase
  - Result: VMs stayed stopped after backup failures
  - **Impact:** Any backup failure left VMs in stopped state
  
### ✨ Added

- **Unconditional VM Recording**: All VMs now recorded for restart in `backup-start`, regardless of current state
- **Backup-Abort Handling**: VMs explicitly added to restart list when backups abort/fail
- **Enhanced Logging**: Clear indication when VMs recorded for restart

### 🔄 Changed

- **Improved**: `record_original_state()` now always records VMs without status check:
  ```bash
  # Before (v2.3) - BROKEN with race condition:
  if is_vm_running $vmid; then
      echo "$vmid" >> "$ORIGINAL_STATE_FILE"
  fi
  
  # After (v2.4) - FIXED:
  # Always record - vzdump will stop it, we must restart it
  echo "$vmid" >> "$ORIGINAL_STATE_FILE"
  ```
  
- **Improved**: `backup-abort` phase now ensures VM restart:
  ```bash
  backup-abort)
      if [ -n "$VMID" ]; then
          echo "$VMID" >> "$ORIGINAL_STATE_FILE"
      fi
      ;;
  ```

### 📊 Real-World Impact

**Discovered Issue:**
- VM 101 backup aborted due to guest-agent timeout
- Hook log showed NO "recording for restart" entry (race condition)
- VM stayed stopped after backup job completed
- Manual intervention required to identify and restart VM

**After Fix:**
- All VMs automatically added to restart list
- VMs restart even after backup failures/aborts
- No manual intervention needed
- Works reliably with VMs that lack qemu-guest-agent

### 🔬 Technical Details

**Root Cause Analysis:**
```
Timeline of race condition:
T0: vzdump starts backup job
T1: vzdump begins VM shutdown (mode: stop)
T2: Hook backup-start phase called
T3: is_vm_running() returns false (VM shutting down)
T4: VM not recorded in restart list
T5: Backup completes/fails
T6: job-end: No VMs to restart
```

**Why it only affected some VMs:**
- VMs sharing a GPU had conflicts → other VMs stopped → recorded in STATEFILE ✅
- VMs with unique GPU had no conflicts → nothing stopped → VM itself not recorded ❌
- VM 101 had unique GPU 01:00.0 → affected by race condition

### 📚 Documentation

- Added comprehensive bug analysis document
- Documented race condition mechanics
- Added troubleshooting guide for VM restart failures

### ⚙️ Compatibility

- ✅ Proxmox VE 7.x and 8.x
- ✅ All backup modes (stop, suspend, snapshot)
- ✅ VMs with and without qemu-guest-agent
- ✅ Single-GPU and multi-GPU configurations
- ✅ Backward compatible with all v2.x configurations

---

## [2.2.0] - 2025-11-04

### 🔥 Critical Fix - Production Ready Release

This release fixes a critical bug that made versions 2.0-2.1 non-functional with `--mode stop` backups (the most common backup mode for GPU VMs). **If you're using v2.0 or v2.1, upgrade immediately!**

### 🐛 Critical Fixes

- **CRITICAL: Fixed VMID parsing for `--mode stop` backups**
  - Proxmox passes arguments as: `backup-start stop 105` 
  - v2.0-2.1 incorrectly captured `$2` ("stop") as VMID
  - v2.2 correctly identifies mode in `$2` and reads VMID from `$3`
  - **Impact:** Without this fix, hook fails silently and backups proceed without VM management
  - **Symptoms:** Log shows `[VM stop]` instead of `[VM 105]`, VMs not stopped/restarted

### ✨ Added

- **Smart VMID Detection**: Automatically detects if `$2` is a backup mode (stop/snapshot/suspend)
- **Backward Compatibility**: Correctly handles both `backup-start stop 105` and `backup-start 105` formats
- **Enhanced Logging**: VMID now correctly logged for all operations
- **Production Testing**: Extensively tested with real-world Proxmox 8.x setups

### 🔄 Changed

- **Improved**: VMID variable assignment with mode detection:
  ```bash
  # Before (v2.0-2.1) - BROKEN:
  VMID=$2  # Got "stop" instead of "105"
  
  # After (v2.2) - FIXED:
  if [[ "$2" =~ ^(stop|snapshot|suspend)$ ]]; then
      VMID=$3  # Correctly gets "105"
  else
      VMID=$2  # Backwards compatible
  fi
  ```
- **Updated**: Hook script version to 2.2 with detailed fix comments
- **Enhanced**: Error detection and state management

### 📚 Documentation

- **Updated**: README with critical fix explanation
- **Added**: Troubleshooting section for v2.0-2.1 bug symptoms
- **Added**: Migration guide from v2.0-2.1 to v2.2
- **Updated**: CHANGELOG with detailed fix information
- **Added**: GPU D3cold power state troubleshooting
- **Improved**: Testing and verification procedures

### 🧪 Testing

**Verified Scenarios:**
- ✅ `vzdump --mode stop` with single VM
- ✅ `vzdump --mode stop` with multiple GPU VMs
- ✅ `vzdump --all 1 --mode stop` (all VMs)
- ✅ Concurrent VM stops and restarts
- ✅ GPU conflict resolution (RTX 3090 Ti, RTX 4090)
- ✅ State file cleanup after job completion
- ✅ Backup abort scenarios

**Test Results:**
```log
[2025-11-04 09:08:02] [backup-start] [VM 102] ✅ VM/CT 102 uses GPU 05:00
[2025-11-04 09:08:02] [backup-start] [VM 102] ✅ VMs/CTs with GPU 05:00: 102 103 104 105
[2025-11-04 09:08:03] [backup-start] [VM 102] ✅ Stopping VM/CT 104
[2025-11-04 09:15:30] [backup-end] [VM 102] ✅ Backup completed
[2025-11-04 09:15:30] [job-end] ✅ Starting VM 104
```

### ⚠️ Breaking Changes

**None** - This is a bug fix release. All v2.0 configurations remain compatible.

### 📝 Upgrade Instructions

**From v2.0 or v2.1 to v2.2 (REQUIRED):**

```bash
# Backup old version
cd /usr/local/bin
mv backup-gpu-hook.sh backup-gpu-hook.sh.v2.0

# Download v2.2
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/backup-gpu-hook.sh
chmod +x backup-gpu-hook.sh

# Test immediately
vzdump 102 --storage pbs-ptest --mode stop
tail -20 /var/log/vzdump-gpu-hook.log
```

**Verification:**
Look for correct VMID in logs:
- ✅ Good: `[backup-start] [VM 102]`
- ❌ Bad: `[backup-start] [VM stop]`

### 🔍 Technical Details

**Root Cause Analysis:**

Proxmox's vzdump behavior when using `--mode stop`:
```bash
# Proxmox calls hook with:
/usr/local/bin/backup-gpu-hook.sh backup-start stop 105

# Argument positions:
$1 = "backup-start"  # Phase
$2 = "stop"          # Mode (NOT the VMID!)
$3 = "105"           # The actual VMID
```

**The Bug:**
```bash
# v2.0-2.1 code (BROKEN):
VMID=$2  # Captured "stop" as VMID

# Result:
get_vm_gpu("stop")  # Returns empty - no VM named "stop"
# → Hook fails silently
# → VMs not managed
# → Backups fail with GPU conflicts
```

**The Fix:**
```bash
# v2.2 code (FIXED):
if [[ "$2" =~ ^(stop|snapshot|suspend)$ ]]; then
    VMID=$3  # Use $3 when $2 is a mode
else
    VMID=$2  # Use $2 for other scenarios
fi

# Result:
get_vm_gpu("105")  # Correctly finds VM 105's GPU
# → Hook works correctly
# → VMs properly managed
# → Backups succeed
```

### 🏆 Production Validation

**Real-World Test Environment:**
- Proxmox VE 8.x (6.8.12-15-pve kernel)
- NVIDIA RTX 4090 (01:00.0)
- NVIDIA RTX 3090 Ti (05:00.0)
- Multiple VMs sharing GPUs (102, 103, 104, 105)
- Scheduled nightly backups at 02:00
- Proxmox Backup Server (PBS) storage

**Test Scenarios Validated:**
1. Single VM backup while others running ✅
2. Sequential backups of all GPU VMs ✅
3. Backup job with `--all 1` flag ✅
4. Backup abort/error scenarios ✅
5. VM restart after backup completion ✅
6. Multiple GPU groups simultaneously ✅

---

## [2.1.0] - 2025-10-30

### 🔄 Improvements and Bug Fixes

### ✨ Added

- **Improved backup-abort handling**: Better cleanup when backups fail
- **Enhanced Container Support**: More robust LXC container detection
- **Better Error Messages**: Clearer logging for debugging

### 🐛 Fixed

- **Fixed**: State file cleanup in abort scenarios
- **Fixed**: Container GPU detection edge cases
- **Fixed**: Race conditions in VM restart logic

### 📚 Documentation

- **Updated**: Troubleshooting guide
- **Added**: Container-specific examples
- **Improved**: Installation instructions

---

## [2.0.0] - 2025-10-26

### 🎉 Major Release - Zero Configuration!

This is a major rewrite that eliminates all manual configuration. Version 2.0 achieves the original vision of making GPU passthrough backups "just work" automatically.

### ✨ Added

- **Automatic GPU Detection**: Script now dynamically scans all VM/CT configurations before each backup
- **Zero Configuration Installation**: No need to manually define GPU groups
- **Dynamic VM Discovery**: Automatically finds all VMs sharing the same GPU
- **Container (LXC) Support**: Full support for both VMs and LXC containers
- **Future-Proof Design**: Automatically adapts when VMs are added/removed or GPU assignments change
- **Intelligent Scanning**: Builds dynamic GPU-to-VM mapping on-the-fly
- **Enhanced Logging**: Clearer log messages showing automatic detection process
- **Improved Installer**: Setup script now downloads hook from GitHub with embedded fallback
- **Better Error Handling**: More robust PCI address parsing and VM detection
- **Installation Summary**: Installer generates comprehensive summary of detected configuration

### 🔄 Changed

- **BREAKING**: Removed manual `GPU_GROUPS` configuration (no longer needed!)
- **Improved**: Hook script completely rewritten with dynamic detection
- **Improved**: Setup installer now fully automatic with zero user configuration
- **Enhanced**: Log messages now show dynamic detection results
- **Updated**: Documentation completely rewritten for v2.0 workflow
- **Modernized**: Code structure optimized for dynamic operations

### 🐛 Fixed

- **Fixed**: VMs could be forgotten in manual GPU group configuration (v1.0 bug)
- **Fixed**: Configuration required updates when adding/removing VMs
- **Fixed**: GPU address parsing now handles all PCI format variations
- **Fixed**: Container GPU detection now works correctly with cgroup settings
- **Fixed**: Race conditions eliminated with improved state management

### 📚 Documentation

- **Updated**: README completely rewritten emphasizing zero-configuration
- **Updated**: README.de.md updated with v2.0 features
- **Added**: Detailed upgrade guide from v1.0 to v2.0
- **Added**: Real-world examples showing automatic detection
- **Added**: Comparison showing v1.0 vs v2.0 workflow differences
- **Improved**: Troubleshooting section with v2.0-specific guidance
- **Added**: Installation summary document generated automatically

### 🔧 Technical Details

**New Functions:**
- `get_vm_gpu()`: Extracts GPU PCI address from any VM/CT configuration
- `find_all_vms_with_gpu()`: Dynamically discovers all VMs sharing a GPU
- Improved `is_vm_running()`: Better detection for VMs and containers
- Enhanced `stop_vm()`/`start_vm()`: Universal handling of VMs and containers

**Improved Algorithm:**
```
Before (v1.0):                      After (v2.0):
┌─────────────────────┐            ┌──────────────────────┐
│ Manual GPU Groups   │            │ Automatic Scanning   │
│ GPU_GROUPS["..."]   │    →       │ Scans /etc/pve/      │
│ (error-prone)       │            │ Builds dynamic map   │
│ (needs maintenance) │            │ (zero maintenance)   │
└─────────────────────┘            └──────────────────────┘
```

### ⚠️ Breaking Changes

**Migration from v1.0:**

The manual `GPU_GROUPS` configuration is no longer needed or used. Simply run the new installer and all GPU detection happens automatically.

**Before (v1.0):**
```bash
# Manual configuration required
declare -A GPU_GROUPS
GPU_GROUPS["01:00.0"]="100 101 102"
GPU_GROUPS["05:00.0"]="110 111"
# Must update when VMs change!
```

**After (v2.0):**
```bash
# Zero configuration!
# Script automatically discovers everything
```

---

## [1.0.0] - 2025-10-01

### 🎉 Initial Release

First public release of the Proxmox GPU Backup Hook.

### ✨ Features

- **Manual GPU Group Configuration**: Define GPU-to-VM mappings
- **VM Conflict Management**: Stop/start VMs sharing GPUs
- **State File Management**: Track stopped VMs for restart
- **Comprehensive Logging**: Detailed operation logs
- **Hook Phase Support**: Integration with vzdump phases
- **Setup Script**: Automated installation assistant

### 📚 Documentation

- **README.md**: Complete user guide
- **README.de.md**: German documentation
- **CHANGELOG.md**: Version history
- **CONTRIBUTING.md**: Contribution guidelines
- **LICENSE**: MIT License

### 🔧 Technical Implementation

- Bash script hook for Proxmox vzdump
- Manual GPU group configuration via associative arrays
- State file for VM restart tracking
- Log rotation configuration
- vzdump.conf integration

---

## Version Comparison

| Feature | v1.0 | v2.0 | v2.1 | v2.2 |
|---------|------|------|------|------|
| GPU Detection | Manual | Auto | Auto | Auto |
| VMID Parsing | Basic | Basic | Basic | **Fixed** |
| Configuration | Required | None | None | None |
| Container Support | No | Yes | Yes+ | Yes+ |
| Production Ready | Limited | No* | No* | **Yes** |

*v2.0-2.1 had critical VMID parsing bug with `--mode stop`

---

## Roadmap

### Planned for v2.3
- [ ] Web UI for configuration management
- [ ] Prometheus metrics export
- [ ] Advanced notification system
- [ ] Multi-cluster support

### Under Consideration
- [ ] GPU temperature monitoring
- [ ] Backup performance analytics
- [ ] Automated restore testing
- [ ] Integration with Proxmox HA

---

## Support

For bug reports, feature requests, or questions:
- **GitHub Issues**: https://github.com/alflewerken/proxmox-gpu-backup-hook/issues
- **Discussions**: https://github.com/alflewerken/proxmox-gpu-backup-hook/discussions
- **Proxmox Forum**: https://forum.proxmox.com/

---

**Maintained with ❤️ by the Proxmox community**
