# Changelog

All notable changes to the Proxmox GPU Backup Hook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-26

### Added
- ✅ Initial release of Proxmox GPU Backup Hook
- ✅ Automatic GPU conflict detection and resolution
- ✅ Support for NVIDIA, AMD, and Intel GPUs
- ✅ Intel SR-IOV Virtual Function support
- ✅ Multi-GPU environment support with independent VM groups
- ✅ Automatic VM state preservation and restoration
- ✅ Sequential backup processing for GPU-sharing VMs
- ✅ Comprehensive logging with automatic rotation
- ✅ One-line installation script
- ✅ Automatic example configuration generation
- ✅ Professional documentation (English & German)
- ✅ MIT License
- ✅ Contributing guidelines
- ✅ Detailed troubleshooting guide

### Documentation
- 📖 Complete README in English and German
- 📖 Installation and configuration guides
- 📖 Real-world configuration examples
- 📖 Troubleshooting section with common issues
- 📖 Contributing guidelines for community contributions

### Technical Details
- Hook integration via `/etc/vzdump.conf`
- PCI address-based GPU conflict detection
- State tracking via temporary files in `/tmp`
- Log rotation configured for 7-day retention
- Bash 4.0+ compatible
- Proxmox VE 7.x and 8.x support

### Files Structure
```
/usr/local/bin/backup-gpu-hook.sh    # Main hook script
/etc/vzdump.conf                     # Proxmox backup configuration
/etc/logrotate.d/vzdump-gpu-hook    # Log rotation
/var/log/vzdump-gpu-hook.log        # Operation logs
```

---

## [Unreleased]

### Planned Features
- Web UI integration for easier configuration
- Email notifications for backup events
- Enhanced error recovery mechanisms
- Performance optimizations for large VM counts
- Container (LXC) backup support
- Backup scheduling optimization
- Prometheus metrics exporter

### Under Consideration
- GUI configuration tool
- Backup verification system
- Cloud backup integration
- Multi-node Proxmox cluster support
- Advanced scheduling algorithms
- Webhook notifications

---

## Version History

### Version Numbering
- **Major version** (X.0.0): Breaking changes or major rewrites
- **Minor version** (1.X.0): New features, backward compatible
- **Patch version** (1.0.X): Bug fixes, documentation updates

### Support Policy
- Latest version receives active development and support
- Previous major version receives security updates for 6 months
- Community support available via GitHub Issues

---

## Migration Notes

### From Manual VM Management
If you were previously managing VM stops/starts manually:

1. Remove any manual backup scripts
2. Install this hook using the one-line installer
3. Configure GPU_GROUPS in the hook script
4. Test with a manual backup job
5. Monitor logs during first automated backup

### From Other Hook Scripts
If you have existing hook scripts:

1. Backup your current `/etc/vzdump.conf`
2. Note your existing hook configurations
3. Install this hook (will update vzdump.conf)
4. Verify the hookscript path is correctly set
5. Test backup operations

---

## Known Issues

### Version 1.0.0
- None reported yet

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- How to report bugs
- How to suggest features
- Development workflow
- Testing procedures
- Code style guidelines

---

## Links

- **Repository**: https://github.com/alflewerken/proxmox-gpu-backup-hook
- **Issues**: https://github.com/alflewerken/proxmox-gpu-backup-hook/issues
- **Documentation**: [README.md](README.md) | [README.de.md](README.de.md)
- **License**: [MIT License](LICENSE)

---

## Credits

Developed and maintained by [Alf Lewerken](https://github.com/alflewerken)

Special thanks to:
- The Proxmox VE development team
- The Proxmox community for feedback and testing
- Early adopters who helped identify edge cases

---

**Note**: This changelog will be updated with each release. For the latest changes, check the [commit history](https://github.com/alflewerken/proxmox-gpu-backup-hook/commits/main).
