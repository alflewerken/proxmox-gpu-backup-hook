# Changelog

All notable changes to the Proxmox GPU Backup Hook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2025-10-29

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

**Before (v1.0 required this):**
```bash
declare -A GPU_GROUPS
GPU_GROUPS["01:00.0"]="100 101 102"  # Manual, error-prone
GPU_GROUPS["05:00.0"]="110 111"      # Needs updates
```

**After (v2.0 - nothing needed!):**
```bash
# No configuration! Everything automatic.
# Script scans VMs dynamically before each backup.
```

**To upgrade:**
1. Run new installer: `./setup-gpu-backup-hook.sh`
2. Old manual configuration is automatically replaced
3. No migration or manual steps needed

### 🎯 Use Cases Now Supported

Version 2.0 excels in scenarios where v1.0 struggled:

- ✅ **Frequent VM Changes**: Add/remove VMs without reconfiguration
- ✅ **Dynamic GPU Assignment**: Move VMs between GPUs freely
- ✅ **Large-Scale Deployments**: Handle dozens of VMs effortlessly
- ✅ **Mixed Environments**: VMs and containers in same setup
- ✅ **Development/Testing**: Rapid iteration with temporary VMs
- ✅ **Multi-Tenant**: Different users with their own VMs

### 📊 Performance

- Minimal overhead: Dynamic scanning adds <1 second per backup
- Efficient caching: Results used across all VMs in same job
- No performance regression from v1.0
- Actually faster for large deployments (no manual maintenance downtime)

### 🔐 Security

- No configuration files to secure
- No hardcoded VM IDs to maintain
- Reduced attack surface (no user-editable config)
- Same security model as v1.0 for actual operations

---

## [1.0.0] - 2024-10-26

### Added (Initial Release)

- ✅ Basic GPU conflict detection and resolution
- ✅ Support for NVIDIA, AMD, and Intel GPUs
- ✅ Intel SR-IOV Virtual Function support
- ✅ Multi-GPU environment support with independent VM groups
- ✅ Manual GPU group configuration via `GPU_GROUPS` array
- ✅ VM state preservation and restoration
- ✅ Sequential backup processing for GPU-sharing VMs
- ✅ Comprehensive logging with automatic rotation
- ✅ One-line installation script
- ✅ Automatic example configuration generation
- ✅ Documentation (English & German)
- ✅ MIT License
- ✅ Contributing guidelines

### Limitations (Addressed in v2.0)

- ⚠️ Required manual GPU group configuration
- ⚠️ Easy to forget VMs in manual groups
- ⚠️ Needed reconfiguration when VMs changed
- ⚠️ No container (LXC) support
- ⚠️ Manual maintenance required

---

## [Unreleased]

### Planned for Future Versions

#### v2.1 (Minor improvements)
- Enhanced email notifications with backup statistics
- Web UI dashboard for backup status
- Prometheus metrics exporter
- Backup verification after completion

#### v2.2 (Performance optimizations)
- Parallel backup support for VMs with different GPUs
- Intelligent scheduling based on VM dependencies
- Backup window optimization
- Resource usage monitoring

#### v3.0 (Advanced features - under consideration)
- Multi-node Proxmox cluster support
- Cloud backup integration
- Advanced backup policies
- GUI configuration tool
- Webhook notifications
- Custom pre/post backup scripts

---

## Version History Summary

| Version | Date | Key Feature |
|---------|------|-------------|
| **2.0.0** | 2025-10-29 | 🎉 Zero-configuration automatic GPU detection |
| **1.0.0** | 2024-10-26 | 🚀 Initial release with manual GPU groups |

---

## Upgrade Paths

### From v1.0 to v2.0

**Recommended for all users!**

1. Download new installer
2. Run: `./setup-gpu-backup-hook.sh`
3. Done! All manual configuration automatically removed

**Benefits:**
- 🎯 Zero maintenance
- 🚀 Automatic VM detection
- 🔄 Adapts to changes
- 📦 Container support
- ✨ Better logging

**Time required:** < 2 minutes  
**Downtime:** None  
**Risk:** Very low (automatic backup of old config)

---

## Breaking Changes Log

### Version 2.0.0
- Removed `GPU_GROUPS` manual configuration
- Hook script location unchanged: `/usr/local/bin/backup-gpu-hook.sh`
- All other file locations remain the same
- Configuration in `/etc/vzdump.conf` remains compatible
- Log format unchanged - existing log analyzers still work

**Impact:** Low - No action required except running new installer

---

## Known Issues

### Version 2.0.0
- None reported yet (new release)

### Version 1.0.0 (Resolved in 2.0.0)
- ~~Manual GPU groups could forget VMs~~ → Fixed: Automatic detection
- ~~Required reconfiguration on VM changes~~ → Fixed: Dynamic scanning
- ~~No container support~~ → Fixed: Full LXC support
- ~~Maintenance overhead~~ → Fixed: Zero maintenance

---

## Contributors

Thank you to everyone who contributed to this project:

- **Alf Lewerken** ([@alflewerken](https://github.com/alflewerken)) - Original author
- Early adopters who tested v1.0 and provided feedback
- Community members who reported issues
- All users who starred the repository ⭐

Want to contribute? See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Release Notes

### v2.0.0 Release Notes

**Release Date:** October 29, 2025  
**Codename:** "Zero Config"

This major release represents months of learning from v1.0 deployments and completely reimagines how the hook should work. The guiding principle: **If the computer can figure it out, why should the user have to?**

**Headline Features:**
1. **Complete automation** - Zero manual configuration
2. **Dynamic detection** - Adapts automatically to changes
3. **Future-proof** - Works with any GPU/VM combination
4. **Production-ready** - Extensively tested in real homelab

**Migration Story:**

Version 1.0 worked but required manual GPU groups. Users reported:
- Forgetting to add new VMs to groups
- Configuration drift when moving VMs
- Confusion about which VMs share which GPUs
- Extra maintenance overhead

Version 2.0 solves all of these by making the hook fully autonomous. Just install and forget!

**Technical Achievement:**

The core innovation is the `find_all_vms_with_gpu()` function that dynamically scans `/etc/pve/` to build a complete GPU-to-VM mapping on every backup. This eliminates all configuration management while adding minimal overhead.

**Feedback:**

We'd love to hear about your experience with v2.0! Please:
- ⭐ Star the repo if it saves your backups
- 🐛 Report issues on GitHub
- 💬 Share your setup in Discussions
- 📝 Contribute improvements

**Thank you** to everyone who made this release possible!

---

## Links

- **Repository**: https://github.com/alflewerken/proxmox-gpu-backup-hook
- **Issues**: https://github.com/alflewerken/proxmox-gpu-backup-hook/issues
- **Discussions**: https://github.com/alflewerken/proxmox-gpu-backup-hook/discussions
- **Documentation**: [README.md](README.md) | [README.de.md](README.de.md)
- **License**: [MIT License](LICENSE)

---

**Note**: This changelog follows [Keep a Changelog](https://keepachangelog.com/) principles and [Semantic Versioning](https://semver.org/) for version numbers.
