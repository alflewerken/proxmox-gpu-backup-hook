# Proxmox GPU Backup Hook 🔧

🇬🇧 English | [🇩🇪 Deutsch](README.de.md)

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-7.x%20%7C%208.x-orange.svg)](https://www.proxmox.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-2.0-blue.svg)](CHANGELOG.md)
[![GitHub issues](https://img.shields.io/github/issues/alflewerken/proxmox-gpu-backup-hook)](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)

**Zero-configuration automatic backup solution for Proxmox VMs with GPU passthrough. Prevents backup failures caused by GPU conflicts. One-line installation - no manual configuration needed!**

> **"From a Proxmox admin for Proxmox admins"**
>
> After hours of failed backup jobs and manual VM juggling, I built this hook to automate what should have been automatic. Version 2.0 makes it even easier - **fully automatic GPU detection, zero configuration required!**

## 🆕 What's New in Version 2.0

✨ **Zero-Configuration Installation** - No manual GPU group setup needed  
✨ **Dynamic GPU Detection** - Automatically scans all VM configurations  
✨ **Future-Proof** - Adapts automatically when you add/remove VMs or change GPU assignments  
✨ **Container Support** - Works with both VMs and LXC containers  
✨ **Intelligent Scanning** - Detects GPU sharing automatically before each backup  

**Version 1.0 required manual configuration:**
```bash
# Old way - manual GPU groups (error-prone, maintenance required)
GPU_GROUPS["01:00.0"]="100 101 102"  # Easy to forget VMs!
GPU_GROUPS["05:00.0"]="110 111"      # Needs updating when VMs change
```

**Version 2.0 is fully automatic:**
```bash
# New way - zero configuration!
# Script automatically discovers:
# - All VMs and containers
# - Their GPU assignments
# - Conflicts before each backup
# No maintenance needed when VMs change!
```

---

## ⭐ Support the Project

If you find this project useful, please consider giving it a star! It helps others discover the solution and motivates continued development.

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/network)

</div>

---

## 🎯 The Problem

When multiple Proxmox VMs share the same physical GPU (GPU passthrough), they cannot run simultaneously. During backup operations, this causes VMs to be skipped if another VM is already using the shared GPU.

**Real-world scenario:**
```
VM 100: Windows Gaming PC     ─┐
VM 101: Ubuntu ML Workstation ─┼─ All share RTX 4090 (01:00.0)
VM 102: AI Development Box    ─┘

Backup starts at 02:00:
  ✅ VM 100 backs up (was running, gets stopped)
  ❌ VM 101 SKIPPED! GPU conflict with VM 100
  ❌ VM 102 SKIPPED! GPU conflict with VM 100
  
Result: 66% backup failure rate 😱
```

## ✅ The Solution

This hook script provides intelligent GPU conflict resolution with **zero configuration**:

✅ **Automatic GPU Detection** - Dynamically scans VM configurations  
✅ **Zero Manual Setup** - No GPU groups to configure  
✅ **Smart VM Orchestration** - Stops conflicting VMs before backup starts  
✅ **Sequential Processing** - Backs up all VMs one at a time  
✅ **Automatic VM Restart** - Restarts originally running VMs after completion  
✅ **Multi-GPU Support** - Handles unlimited GPUs automatically  
✅ **Intel SR-IOV Compatible** - Works with Intel iGPU Virtual Functions  
✅ **Container Support** - Manages both VMs and LXC containers  
✅ **Future-Proof** - Adapts automatically to VM/GPU changes  
✅ **Comprehensive Logging** - Detailed logs with automatic rotation  

**Result after installing this hook:**
```
Backup starts at 02:00:
  ✅ VM 100 backs up (conflicts auto-detected and resolved)
  ✅ VM 101 backs up (GPU sharing managed automatically)
  ✅ VM 102 backs up (sequential processing)
  ✅ All originally running VMs restarted
  
Result: 100% backup success rate! 🎉
```

---

## 🚀 Quick Start - One-Line Installation

Install the complete hook system with a single command - **no configuration needed**:

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

**Manual installation:**
```bash
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh
```

**The installer automatically:**
- ✅ Downloads and installs the hook script
- ✅ Configures Proxmox backup hooks
- ✅ Sets up log rotation
- ✅ Tests the installation
- ✅ Scans and detects your GPU VMs
- ✅ **No manual configuration required!**

---

## 🎮 Usage - It Just Works!

### Step 1: Install (Already Done Above)

One command, fully automatic. That's it!

### Step 2: Create Backup Job

Configure a backup job via Proxmox WebUI:

1. Navigate to **Datacenter → Backup → Add**
2. Configure schedule (e.g., `02:00` for 2 AM)
3. Set mode to **Stop** (already configured by installer)
4. Select your backup storage
5. Choose VMs to backup

**The hook automatically handles all GPU conflicts!**

### Step 3: Monitor (Optional)

Watch the first backup to see the magic:

```bash
tail -f /var/log/vzdump-gpu-hook.log
```

You'll see the hook automatically:
- Detecting VMs and their GPU assignments
- Identifying GPU conflicts
- Stopping/starting VMs as needed
- Managing everything automatically

---

## 📋 Supported Scenarios

| Scenario | Status | Notes |
|----------|--------|-------|
| NVIDIA GPUs (GeForce, Quadro, Tesla) | ✅ Fully Automatic | Zero configuration |
| AMD GPUs (Radeon, Instinct) | ✅ Fully Automatic | Zero configuration |
| Intel GPUs (UHD, Arc) with SR-IOV | ✅ Fully Automatic | VFs handled correctly |
| Multiple GPUs with different VMs | ✅ Fully Automatic | All GPU types |
| Mixed VM/LXC environments | ✅ Fully Automatic | Containers included |
| Dynamic VM configurations | ✅ Fully Automatic | Adapts to changes |
| Single GPU shared by 10+ VMs | ✅ Fully Automatic | Sequential processing |
| Adding new GPU VMs | ✅ Fully Automatic | Detected immediately |
| Changing GPU assignments | ✅ Fully Automatic | No reconfiguration |

---

## 🔍 How It Works

### Dynamic Detection Process

**Before Each Backup:**
```
1. Hook scans all VM/CT configurations in /etc/pve/
2. Extracts GPU PCI addresses from hostpci settings
3. Builds dynamic map of which VMs share which GPUs
4. Identifies conflicts for the current backup VM
5. Stops conflicting VMs temporarily
6. Proceeds with backup
7. Restarts stopped VMs after job completes
```

### Detailed Example

```
System State:
  VM 100 (RTX 4090 @ 01:00.0) - Running
  VM 101 (RTX 4090 @ 01:00.0) - Stopped
  VM 102 (RTX 4090 @ 01:00.0) - Running
  VM 110 (RTX 3090 @ 05:00.0) - Running

Backup Process (Automatic):
  
  📊 Job Start
     → Scan: Found VMs 100,101,102 share GPU 01:00.0
     → Scan: Found VM 110 uses GPU 05:00.0
     → Saved: VMs 100,102,110 were running
  
  📦 Backup VM 100
     → Detected: VMs 101,102 also use GPU 01:00.0
     → Action: Stop VM 102 (was running)
     → Backup VM 100
     → Success
  
  📦 Backup VM 101
     → Detected: VMs 100,102 also use GPU 01:00.0
     → Action: All already stopped
     → Backup VM 101
     → Success
  
  📦 Backup VM 102
     → Detected: VMs 100,101 also use GPU 01:00.0
     → Action: All already stopped
     → Backup VM 102
     → Success
  
  📦 Backup VM 110
     → Detected: No other VMs use GPU 05:00.0
     → Action: No conflicts, VM stays running
     → Backup VM 110
     → Success
  
  ✅ Job Complete
     → Restart: VM 100 (was originally running)
     → Restart: VM 102 (was originally running)
     → VM 110 stayed running throughout
     → VM 101 stays stopped (was not running originally)

Final State (Preserved):
  VM 100 - Running ✅
  VM 101 - Stopped ✅
  VM 102 - Running ✅
  VM 110 - Running ✅
```

---

## 📊 Files and Directories

```
/usr/local/bin/
└─ backup-gpu-hook.sh              # Main hook script (v2.0)
                                   # Automatic GPU detection
                                   # No configuration needed

/etc/
└─ vzdump.conf                     # Proxmox backup configuration
                                   # (hookscript reference added)

/etc/logrotate.d/
└─ vzdump-gpu-hook                 # Log rotation config
                                   # (weekly rotation, 4 weeks retention)

/var/log/
└─ vzdump-gpu-hook.log            # Detailed operation log
                                   # Shows automatic detection

/tmp/
└─ vzdump-gpu-stopped-vms.state   # Temporary state tracking
                                   # (automatic, ephemeral)
```

---

## 🛠️ Troubleshooting

### Check Logs

```bash
# View recent activity
tail -100 /var/log/vzdump-gpu-hook.log

# Follow in real-time
tail -f /var/log/vzdump-gpu-hook.log

# Search for issues
grep -E "(ERROR|WARNING)" /var/log/vzdump-gpu-hook.log
```

### Common Questions

#### "How do I know it's working?"

Check the log after your first backup:
```bash
cat /var/log/vzdump-gpu-hook.log
```

You should see entries like:
```
[2025-10-29 02:00:01] [backup-start] [VM 100] VM/CT 100 uses GPU 01:00.0
[2025-10-29 02:00:01] [backup-start] [VM 100] VMs/CTs with GPU 01:00.0: 100 101 102
[2025-10-29 02:00:01] [backup-start] [VM 100] Stopping VM/CT 102 (uses same GPU)
```

#### "Do I need to configure anything?"

**No!** Version 2.0 is fully automatic. The script:
- Scans your VMs automatically
- Detects GPU assignments
- Manages conflicts dynamically
- Adapts to changes automatically

#### "What if I add a new VM with GPU?"

Nothing! The hook automatically detects it on the next backup. No configuration changes needed.

#### "What if I change a VM's GPU?"

The hook will automatically detect the change on the next backup. Zero maintenance required.

### Manual Testing

Test the hook manually:

```bash
# Test basic functionality
/usr/local/bin/backup-gpu-hook.sh job-start test-$(date +%s)

# Check what was detected
tail -20 /var/log/vzdump-gpu-hook.log

# Simulate a VM backup (replace 100 with your VM ID)
/usr/local/bin/backup-gpu-hook.sh backup-start 100

# Check the log to see what VMs were detected
tail -10 /var/log/vzdump-gpu-hook.log
```

### Verify Installation

```bash
# Check hook script exists and is executable
ls -la /usr/local/bin/backup-gpu-hook.sh

# Should show: -rwxr-xr-x

# Check vzdump.conf configuration
grep "backup-gpu-hook" /etc/vzdump.conf

# Should show: script: /usr/local/bin/backup-gpu-hook.sh

# Test hook execution
/usr/local/bin/backup-gpu-hook.sh job-start test
```

---

## 🔄 Upgrading from Version 1.0

If you're upgrading from version 1.0 with manual GPU groups:

```bash
# Download new installer
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh

# Backup your old config (optional - v2.0 doesn't use it anyway)
cp /usr/local/bin/backup-gpu-hook.sh /usr/local/bin/backup-gpu-hook.sh.v1-backup

# Run installer (will upgrade automatically)
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh

# That's it! No configuration migration needed.
```

**Benefits of upgrading:**
- ✅ Remove all manual GPU group configurations
- ✅ Automatic detection of all VMs
- ✅ No maintenance when VMs change
- ✅ Support for containers (LXC)
- ✅ Better error handling

---

## 🖥️ Real-World Examples

### Example 1: Home Lab with Multiple GPUs

**Hardware:**
- Intel UHD 770 with SR-IOV (7 VFs)
- NVIDIA RTX 4090
- NVIDIA RTX 3090 Ti

**VMs:**
- 12 VMs total
- 3 VMs share RTX 4090
- 6 VMs share RTX 3090 Ti
- 3 VMs use Intel UHD VFs

**Configuration Required:**
```bash
# Version 2.0:
None! Fully automatic.

# Version 1.0 would need:
GPU_GROUPS["01:00.0"]="100 101 102"      # RTX 4090
GPU_GROUPS["05:00.0"]="104 105 106 107 108 112"  # RTX 3090 Ti
GPU_GROUPS["00:02.1"]="200"
GPU_GROUPS["00:02.2"]="201"
GPU_GROUPS["00:02.3"]="202"
# ... 4 more lines!
```

### Example 2: AI/ML Workstation Farm

**Hardware:**
- 4× NVIDIA RTX 4090
- 16 VMs (4 per GPU)

**Scenario:**
- Frequent VM creation/deletion
- GPU reassignments for different workloads
- Mix of Ubuntu and Windows VMs

**Version 2.0 Advantage:**
No configuration updates needed when:
- Creating new VMs
- Deleting old VMs  
- Moving VMs between GPUs
- Changing GPU assignments

Everything detected automatically!

### Example 3: Development Environment

**Hardware:**
- 1× AMD Radeon RX 7900 XTX
- 5 VMs sharing the GPU

**Use Case:**
- Dev/Test/Staging/Production/Demo VMs
- VMs often started/stopped manually
- Different VMs running at different times

**Version 2.0 Benefit:**
Hook preserves original VM states:
- Running VMs restart after backup
- Stopped VMs stay stopped
- No manual VM management needed

---

## 📝 Requirements

- **Proxmox VE**: Version 7.x or 8.x
- **Shell**: Bash 4.0 or higher (standard on Proxmox)
- **Permissions**: Root access for installation
- **VMs**: Using GPU passthrough (`hostpci` parameter)
- **Backup Mode**: Will automatically set to `stop` mode
- **Internet**: For initial installation (downloads script)

**No other dependencies!** Works with standard Proxmox installation.

---

## 🤝 Contributing

Contributions are welcome! Whether it's bug reports, feature requests, or code improvements.

### Ways to Contribute

1. **⭐ Star the Repository**: Help others discover this solution
2. **🐛 Report Issues**: [Open an issue](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
3. **💡 Suggest Features**: Share your ideas for improvements
4. **🔧 Submit Pull Requests**: Code improvements are appreciated
5. **📖 Improve Documentation**: Help make the docs even better
6. **💬 Share Your Experience**: Write about your setup and results

### Development Setup

```bash
# Clone repository
git clone https://github.com/alflewerken/proxmox-gpu-backup-hook.git
cd proxmox-gpu-backup-hook

# Test on your Proxmox server
scp setup-gpu-backup-hook.sh root@your-proxmox-server:/tmp/
ssh root@your-proxmox-server
cd /tmp && ./setup-gpu-backup-hook.sh

# Review logs
tail -f /var/log/vzdump-gpu-hook.log
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**TL;DR:** 
- ✅ Free to use for personal and commercial purposes
- ✅ Modify and distribute freely
- ✅ No warranty provided (use at your own risk)

---

## 💡 Background & Motivation

This script was born from real frustration managing a Proxmox homelab with multiple VMs sharing GPUs. After countless failed backup jobs and manual VM management, I decided to automate what should have been automatic.

**Version 1.0** solved the problem but required manual configuration - easy to forget VMs or make mistakes when adding new ones.

**Version 2.0** achieves the original vision: **Make Proxmox backups "just work" with GPU passthrough - automatically!**

### The Journey

- **2019**: Started using Proxmox for AI/ML workstations
- **2020-2024**: Managed GPU conflicts manually (painful!)
- **October 2024**: Built v1.0 with manual GPU groups
- **October 2025**: Released v2.0 with full automation

If you're running:
- 🎮 Gaming VMs
- 🤖 AI/ML workstations
- 🎨 Rendering farms
- 💻 Development environments
- 🏠 Any homelab with GPU passthrough

This hook will save you the headache I went through building and managing these systems.

---

## 🙏 Acknowledgments

- **Proxmox VE Team** - For the excellent virtualization platform
- **The Proxmox Community** - For sharing knowledge and troubleshooting
- **GPU Passthrough Pioneers** - For documenting the complex setup process
- **Early Adopters** - For testing and feedback on v1.0
- **Contributors** - For improvements and bug reports

---

## 💬 About the Author

> *"After managing datacenter infrastructure for 30+ years (SGI, Sun, IBM) and building multiple AI workstation companies, I know what it's like to fight with hardware passthrough. This hook is my contribution to making life easier for fellow sysadmins and homelab enthusiasts."*
>
> *- Alf Lewerken, System Administrator & Proxmox user since 2019*

**Tech Background:**
- 30+ years in system administration
- Former SGI, Sun Microsystems, IBM datacenter experience
- Built and sold AI workstation companies
- Aviation engineer (develops aerobatic aircraft!)
- Maintains vintage SGI systems (Octane2, Indigo)

---

## 📚 Additional Resources

- **GitHub Repository**: https://github.com/alflewerken/proxmox-gpu-backup-hook
- **Issue Tracker**: https://github.com/alflewerken/proxmox-gpu-backup-hook/issues
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Proxmox Documentation**: https://pve.proxmox.com/wiki/Backup_and_Restore
- **GPU Passthrough Guide**: https://pve.proxmox.com/wiki/PCI_Passthrough

---

## 🔗 Quick Links

| Resource | Link |
|----------|------|
| 📦 Installation Script | [setup-gpu-backup-hook.sh](setup-gpu-backup-hook.sh) |
| 🔧 Hook Script | [backup-gpu-hook.sh](backup-gpu-hook.sh) |
| 📝 Changelog | [CHANGELOG.md](CHANGELOG.md) |
| 🤝 Contributing | [CONTRIBUTING.md](CONTRIBUTING.md) |
| 📜 License | [LICENSE](LICENSE) |
| 🐛 Report Bug | [New Issue](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues/new) |
| 💬 Discussions | [GitHub Discussions](https://github.com/alflewerken/proxmox-gpu-backup-hook/discussions) |

---

<p align="center">
  <b>Made with ❤️ by <a href="https://github.com/alflewerken">Alf Lewerken</a></b><br>
  <i>From a Proxmox admin for Proxmox admins</i><br><br>
  <b>⭐ If this hook saved your backups, please star the repository! ⭐</b>
</p>

---

## 📈 Project Stats

![GitHub release (latest by date)](https://img.shields.io/github/v/release/alflewerken/proxmox-gpu-backup-hook)
![GitHub last commit](https://img.shields.io/github/last-commit/alflewerken/proxmox-gpu-backup-hook)
![GitHub](https://img.shields.io/github/license/alflewerken/proxmox-gpu-backup-hook)
![GitHub contributors](https://img.shields.io/github/contributors/alflewerken/proxmox-gpu-backup-hook)

**Support the project:**  
If you find this useful, give it a ⭐ and share it with others who might benefit!
