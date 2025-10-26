# Contributing to Proxmox GPU Backup Hook

🇬🇧 English | [🇩🇪 Deutsch](CONTRIBUTING.de.md)

First off, thank you for considering contributing to Proxmox GPU Backup Hook! It's people like you that make this tool better for everyone.

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**
```markdown
**Description:**
A clear description of what the bug is.

**Environment:**
- Proxmox VE version: [e.g., 8.1.4]
- GPU model(s): [e.g., NVIDIA RTX 4090]
- Number of VMs: [e.g., 3 VMs sharing one GPU]

**Steps to Reproduce:**
1. Configure GPU_GROUPS with...
2. Start backup job...
3. See error...

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Logs:**
```bash
# Relevant log entries from /var/log/vzdump-gpu-hook.log
```

**Additional Context:**
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description** of the enhancement
- **Use case** - Why would this be useful?
- **Proposed solution** - How do you envision this working?
- **Alternatives considered** - What other solutions did you consider?

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the style guidelines
3. **Test thoroughly** on a Proxmox test environment
4. **Update documentation** if needed (README, inline comments)
5. **Write clear commit messages** following Conventional Commits

**Good commit message examples:**
```bash
feat: Add support for AMD GPUs
fix: Correct VM restart logic for SR-IOV setups
docs: Update troubleshooting section
refactor: Improve PCI address detection
```

## 📝 Style Guidelines

### Bash Script Style

- Use **4 spaces** for indentation (no tabs)
- Keep lines under **100 characters** where possible
- Add **comments** for complex logic
- Use **meaningful variable names**
- Quote **all variable expansions**: `"${VARIABLE}"`
- Use `[[ ]]` for tests instead of `[ ]`
- Always check command success with `|| handle_error`

**Example:**
```bash
# Good
if [[ "${VM_STATUS}" == "running" ]]; then
    qm stop "${VMID}" || {
        log_error "Failed to stop VM ${VMID}"
        return 1
    }
fi

# Bad
if [ $VM_STATUS = "running" ]; then
  qm stop $VMID
fi
```

### Documentation Style

- Use **clear, simple English**
- Include **practical examples**
- Add **step-by-step instructions** where appropriate
- Use **code blocks** for commands
- Keep explanations **concise but complete**

## 🧪 Testing

Before submitting a pull request:

1. **Test on a Proxmox test system** - Never test directly on production!
2. **Test multiple scenarios:**
   - Single GPU with multiple VMs
   - Multiple GPUs with different VM groups
   - Intel SR-IOV Virtual Functions
   - Mixed environments
3. **Verify log output** is clear and helpful
4. **Check for edge cases** (all VMs stopped, all VMs running, backup failures)

**Testing checklist:**
```bash
# 1. Install your modified version
./setup-gpu-backup-hook.sh

# 2. Verify configuration
cat /usr/local/bin/backup-gpu-hook.sh | grep GPU_GROUPS

# 3. Test manually
/usr/local/bin/backup-gpu-hook.sh job-start test
/usr/local/bin/backup-gpu-hook.sh backup-start 100
/usr/local/bin/backup-gpu-hook.sh backup-end 100
/usr/local/bin/backup-gpu-hook.sh job-end test

# 4. Check logs
cat /var/log/vzdump-gpu-hook.log

# 5. Run actual backup
# Monitor: tail -f /var/log/vzdump-gpu-hook.log
```

## 📋 Development Setup

```bash
# 1. Fork and clone
git clone https://github.com/YOUR-USERNAME/proxmox-gpu-backup-hook.git
cd proxmox-gpu-backup-hook

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Make changes and test

# 4. Commit changes
git add .
git commit -m "feat: Add your feature description"

# 5. Push to your fork
git push origin feature/your-feature-name

# 6. Create Pull Request on GitHub
```

## 🌍 Community Guidelines

### Be Respectful

- Be welcoming to newcomers
- Use inclusive language
- Accept constructive criticism gracefully
- Focus on what's best for the community

### Be Patient

- Remember that contributors are volunteering their time
- Not everyone has the same level of expertise
- Debugging Proxmox/GPU issues can be complex

### Be Clear

- Explain your reasoning
- Provide context and examples
- Ask questions if something is unclear

## 📧 Contact

- **Issues**: [GitHub Issues](https://github.com/alflewerken/proxmox-gpu-backup-hook/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alflewerken/proxmox-gpu-backup-hook/discussions)
- **Security Issues**: See [SECURITY.md](SECURITY.md)

## 🎯 Priority Areas

Areas where contributions are especially welcome:

1. **Testing on different hardware**
   - AMD GPUs (all models)
   - Intel Arc GPUs
   - Exotic SR-IOV configurations
   - Mixed vendor setups

2. **Documentation improvements**
   - More real-world examples
   - Troubleshooting guides
   - Video tutorials
   - Translations

3. **Error handling**
   - Better error messages
   - Recovery mechanisms
   - Edge case handling

4. **Performance optimizations**
   - Faster PCI address detection
   - Reduced overhead
   - Parallel operations where safe

5. **Feature additions**
   - Web UI integration
   - Email notifications
   - Backup scheduling optimization
   - Container (LXC) support

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! Every bug report, feature suggestion, and pull request helps make this tool better for the entire Proxmox community. 🙏
