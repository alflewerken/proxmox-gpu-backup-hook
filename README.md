# Proxmox GPU Backup Hook 🔧

🇬🇧 English | [🇩🇪 Deutsch](README.de.md)

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-7.x%20%7C%208.x-orange.svg)](https://www.proxmox.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub issues](https://img.shields.io/github/issues/alflewerken/proxmox-gpu-backup-hook)](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
[![GitHub stars](https://img.shields.io/github/stars/alflewerken/proxmox-gpu-backup-hook?style=social)](https://github.com/alflewerken/proxmox-gpu-backup-hook/stargazers)

**Automatic backup solution for Proxmox VMs with GPU passthrough. Prevents backup failures caused by GPU conflicts. One-line installation.**

> **"From a Proxmox admin for Proxmox admins"**
>
> After hours of failed backup jobs and manual VM juggling, I built this hook to automate what should have been automatic. If you're running multiple VMs with GPU passthrough, this will save you the headache I went through.

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
VM 101: Ubuntu ML Workstation ─┼─ Both use RTX 4090 (01:00.0)
VM 102: AI Development Box    ─┘

Backup starts at 02:00:
  ✅ VM 100 backs up (was running, gets stopped)
  ❌ VM 101 SKIPPED! GPU conflict with VM 100
  ❌ VM 102 SKIPPED! GPU conflict with VM 100
  
Result: 66% backup failure rate 😱
```

## ✅ The Solution

This hook script provides intelligent GPU conflict resolution:

✅ **Automatic GPU Conflict Detection** - Scans PCI configurations to identify shared GPUs  
✅ **Smart VM Orchestration** - Stops conflicting VMs before backup starts  
✅ **Sequential Backup Processing** - Backs up all VMs one at a time  
✅ **Automatic VM Restart** - Restarts originally running VMs after backup completes  
✅ **Multi-GPU Support** - Handles multiple GPUs with different VM groups  
✅ **Intel SR-IOV Compatible** - Works with Intel iGPU Virtual Functions  
✅ **Comprehensive Logging** - Detailed logs with automatic rotation  

**Result after installing this hook:**
```
Backup starts at 02:00:
  ✅ VM 100 backs up (running VMs auto-stopped)
  ✅ VM 101 backs up (conflicts resolved automatically)
  ✅ VM 102 backs up (sequential processing)
  ✅ All originally running VMs restarted
  
Result: 100% backup success rate! 🎉
```

---

## 🚀 Quick Start - One-Line Installation

Install the complete hook system with a single command:

```bash
curl -sL https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh | bash
```

**Manual installation:**
```bash
wget https://raw.githubusercontent.com/alflewerken/proxmox-gpu-backup-hook/main/setup-gpu-backup-hook.sh
chmod +x setup-gpu-backup-hook.sh
./setup-gpu-backup-hook.sh
```

The installer will:
- ✅ Create the hook script at `/usr/local/bin/backup-gpu-hook.sh`
- ✅ Configure Proxmox backup hooks in `/etc/vzdump.conf`
- ✅ Set up log rotation in `/etc/logrotate.d/`
- ✅ Generate example configuration with your VMs
- ✅ Test the installation

---

## 🔧 Configuration

### Step 1: Configure GPU Groups

Edit the hook script to define your GPU-to-VM mappings:

```bash
nano /usr/local/bin/backup-gpu-hook.sh
```

Find the `TODO` section and configure your setup:

```bash
# GPU-to-VM mapping
# Format: GPU_GROUPS["PCI_ADDRESS"]="VM_ID1 VM_ID2 VM_ID3"
declare -A GPU_GROUPS

# Example 1: Single GPU shared by 3 VMs
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090

# Example 2: Multiple GPUs
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090 #1
GPU_GROUPS["05:00.0"]="110 111"      # RTX 3090 Ti

# Example 3: Intel SR-IOV Virtual Functions
GPU_GROUPS["00:02.1"]="200"  # Intel UHD VF1
GPU_GROUPS["00:02.2"]="201"  # Intel UHD VF2
GPU_GROUPS["00:02.3"]="202"  # Intel UHD VF3
```

**Finding your PCI addresses:**
```bash
# List all GPUs
lspci | grep VGA

# Find VM GPU assignments
grep hostpci /etc/pve/qemu-server/*.conf
```

### Step 2: Test the Configuration

```bash
# Test the hook manually
/usr/local/bin/backup-gpu-hook.sh job-start test

# Check the log output
cat /var/log/vzdump-gpu-hook.log
```

### Step 3: Create Backup Job

Configure a backup job via Proxmox WebUI:

1. Navigate to **Datacenter → Backup → Add**
2. Configure schedule (e.g., `02:00` for 2 AM)
3. Set mode to **Stop** (required for GPU passthrough VMs)
4. Select your backup storage
5. Choose VMs to backup

The hook will automatically manage GPU conflicts during the backup.

---

## 📋 Supported Scenarios

| Scenario | Status | Notes |
|----------|--------|-------|
| NVIDIA GPUs (GeForce, Quadro, Tesla) | ✅ Supported | Full PCI passthrough |
| AMD GPUs (Radeon, Instinct) | ✅ Supported | Full PCI passthrough |
| Intel GPUs (UHD, Arc) | ✅ Supported | Including SR-IOV VFs |
| Multiple GPUs with different VMs | ✅ Supported | Separate GPU_GROUPS per device |
| Mixed VM/CT environments | ✅ Supported | Container backups unaffected |
| Automatic VM restart after backup | ✅ Supported | Restores running state |
| Single GPU shared by 10+ VMs | ✅ Supported | Sequential processing |

---

## 🔍 How It Works

### Hook Execution Flow

```
Backup Job Starts (02:00)
│
├─ 1. job-start hook
│   ├─ Save current running VMs state
│   └─ Initialize tracking variables
│
├─ 2. backup-start hook (for each VM)
│   ├─ Identify GPU used by current VM
│   ├─ Find other VMs using same GPU
│   ├─ Stop conflicting VMs
│   └─ Allow backup to proceed
│
├─ 3. backup-end hook (for each VM)
│   ├─ Backup completed
│   └─ Log success/failure
│
└─ 4. job-end hook
    ├─ Restart all originally running VMs
    └─ Clean up temporary state files
```

### Detailed Example

```
Initial State:
  VM 100 (RTX 4090) - Running
  VM 101 (RTX 4090) - Stopped
  VM 102 (RTX 4090) - Running

Backup Process:
  
  1. Job Start
     └─ Saved state: VMs 100,102 were running
  
  2. Backup VM 100
     ├─ GPU 01:00.0 in use by VM 102
     ├─ Stop VM 102 temporarily
     ├─ Backup VM 100
     └─ Success
  
  3. Backup VM 101
     ├─ No GPU conflicts (VM 100 stopped by backup)
     ├─ Backup VM 101
     └─ Success
  
  4. Backup VM 102
     ├─ No GPU conflicts (other VMs stopped)
     ├─ Backup VM 102
     └─ Success
  
  5. Job End
     └─ Restart VMs 100 and 102 (were originally running)

Final State:
  VM 100 (RTX 4090) - Running ✅
  VM 101 (RTX 4090) - Stopped ✅
  VM 102 (RTX 4090) - Running ✅
```

---

## 📊 Files and Directories

The setup script creates the following structure:

```
/usr/local/bin/
└─ backup-gpu-hook.sh              # Main hook script (executable)

/etc/
└─ vzdump.conf                     # Proxmox backup configuration
                                   # (hookscript reference added)

/etc/logrotate.d/
└─ vzdump-gpu-hook                 # Log rotation config
                                   # (daily rotation, 7 days retention)

/var/log/
└─ vzdump-gpu-hook.log            # Detailed operation log

/tmp/
└─ gpu-backup-example.txt         # Generated example config
                                   # (based on your actual VMs)
```

---

## 🛠️ Troubleshooting

### Check Logs

```bash
# View recent log entries
tail -100 /var/log/vzdump-gpu-hook.log

# Follow logs in real-time
tail -f /var/log/vzdump-gpu-hook.log

# Search for errors
grep ERROR /var/log/vzdump-gpu-hook.log
```

### Common Issues

#### VMs Not Being Stopped

**Symptoms:**
- Backups still failing with GPU conflicts
- Log shows no VM stopping actions

**Solution:**
```bash
# 1. Verify GPU_GROUPS configuration
grep "GPU_GROUPS\[" /usr/local/bin/backup-gpu-hook.sh

# 2. Check actual PCI addresses
lspci | grep VGA

# 3. Verify VM configurations
grep hostpci /etc/pve/qemu-server/*.conf

# 4. Ensure PCI addresses match between config and VM definitions
```

#### Hook Not Executing

**Symptoms:**
- No log entries during backup
- Backups run without hook intervention

**Solution:**
```bash
# 1. Check vzdump.conf
cat /etc/vzdump.conf | grep hookscript

# Should show:
# hookscript: /usr/local/bin/backup-gpu-hook.sh

# 2. Verify hook script is executable
ls -la /usr/local/bin/backup-gpu-hook.sh

# Should show: -rwxr-xr-x

# 3. Test hook manually
/usr/local/bin/backup-gpu-hook.sh job-start test
```

#### VMs Not Restarting After Backup

**Symptoms:**
- Backup succeeds but VMs remain stopped
- Originally running VMs don't auto-start

**Solution:**
```bash
# 1. Check job-end hook execution
grep "job-end" /var/log/vzdump-gpu-hook.log

# 2. Verify state file exists during backup
ls -la /tmp/gpu-backup-running-vms-*

# 3. Ensure no errors in log
grep ERROR /var/log/vzdump-gpu-hook.log | tail -20
```

### Manual Testing

Test the complete hook workflow manually:

```bash
# 1. Start job (initializes tracking)
/usr/local/bin/backup-gpu-hook.sh job-start test-$(date +%s)

# 2. Simulate backing up VM 100
/usr/local/bin/backup-gpu-hook.sh backup-start 100

# 3. Complete VM 100 backup
/usr/local/bin/backup-gpu-hook.sh backup-end 100

# 4. End job (restarts VMs)
/usr/local/bin/backup-gpu-hook.sh job-end test-$(date +%s)

# 5. Review log
cat /var/log/vzdump-gpu-hook.log | tail -50
```

---

## 🖥️ Example Configurations

### Configuration 1: Dual RTX 4090 Setup

**Hardware:**
- 2× NVIDIA RTX 4090
- 6 VMs total (3 per GPU)

**Configuration:**
```bash
declare -A GPU_GROUPS
GPU_GROUPS["01:00.0"]="100 101 102"  # RTX 4090 #1 (Gaming, ML, Rendering)
GPU_GROUPS["02:00.0"]="110 111 112"  # RTX 4090 #2 (Development, Testing, Demo)
```

### Configuration 2: Intel SR-IOV with Virtual Functions

**Hardware:**
- Intel UHD Graphics 770
- 7 Virtual Functions enabled
- 7 VMs using VFs

**Configuration:**
```bash
declare -A GPU_GROUPS
GPU_GROUPS["00:02.1"]="200"  # Desktop VM
GPU_GROUPS["00:02.2"]="201"  # Media Server
GPU_GROUPS["00:02.3"]="202"  # Development
GPU_GROUPS["00:02.4"]="203"  # Testing
GPU_GROUPS["00:02.5"]="204"  # Production Web
GPU_GROUPS["00:02.6"]="205"  # Staging
GPU_GROUPS["00:02.7"]="206"  # Demo Environment
```

### Configuration 3: Mixed GPU Environment

**Hardware:**
- 1× NVIDIA RTX 4090 (01:00.0)
- 1× NVIDIA RTX 3090 Ti (05:00.0)
- 1× AMD Radeon RX 7900 XTX (08:00.0)
- Intel UHD with SR-IOV (00:02.x)

**Configuration:**
```bash
declare -A GPU_GROUPS
# NVIDIA Cards
GPU_GROUPS["01:00.0"]="100 101 102"     # RTX 4090 (High-end workloads)
GPU_GROUPS["05:00.0"]="110 111"         # RTX 3090 Ti (ML training)

# AMD Card
GPU_GROUPS["08:00.0"]="120 121 122"     # RX 7900 XTX (Rendering farm)

# Intel SR-IOV
GPU_GROUPS["00:02.1"]="200"             # Light desktop work
GPU_GROUPS["00:02.2"]="201"             # Office applications
```

---

## 📝 Requirements

- **Proxmox VE**: Version 7.x or 8.x
- **Shell**: Bash 4.0 or higher
- **Permissions**: Root access required for installation
- **VMs**: Configured with GPU passthrough (`hostpci` parameter)
- **Backup Mode**: VMs must use `stop` mode for backup (required for GPU passthrough)

---

## 🤝 Contributing

Contributions are welcome! Whether it's bug reports, feature requests, or code improvements.

### Ways to Contribute

1. **Report Issues**: Found a bug? [Open an issue](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
2. **Suggest Features**: Have an idea? Let's discuss it!
3. **Submit Pull Requests**: Code improvements are always appreciated
4. **Share Your Setup**: Help others by sharing your GPU configuration
5. **Star the Repo**: If this solved your problem, give it a ⭐

### Development Setup

```bash
# Clone repository
git clone https://github.com/alflewerken/proxmox-gpu-backup-hook.git
cd proxmox-gpu-backup-hook

# Test on your Proxmox server
scp setup-gpu-backup-hook.sh root@your-proxmox-server:/tmp/
ssh root@your-proxmox-server
cd /tmp && ./setup-gpu-backup-hook.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**TL;DR:** Free to use for private and commercial purposes. No warranty provided.

---

## 💡 Background

This script was born from real frustration managing a Proxmox homelab with multiple VMs sharing GPUs. After countless failed backup jobs and manual VM management, I decided to automate what should have been automatic.

The goal was simple: **Make Proxmox backups "just work" with GPU passthrough.**

If you're running AI workstations, gaming VMs, rendering farms, or any setup with shared GPUs, this hook will save you the headache I went through building and managing these systems.

---

## 🙏 Acknowledgments

- **Proxmox VE Team** - For the excellent virtualization platform
- **The Proxmox Community** - For sharing knowledge and troubleshooting tips
- **GPU Passthrough Pioneers** - For documenting the complex setup process

---

## 💬 About

> *"After managing datacenter infrastructure for 30+ years (SGI, Sun, IBM) and building multiple AI workstation companies, I know what it's like to fight with hardware passthrough. This hook is my contribution to making life easier for fellow sysadmins and homelab enthusiasts."*
>
> *- Alf, System Administrator & Proxmox user since 2019*

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/alflewerken">Alf Lewerken</a><br>
  <i>From a Proxmox admin for Proxmox admins</i>
</p>

---

**⭐ If this hook saved your backups, consider giving the repo a star!**
