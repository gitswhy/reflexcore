# ReflexCore: Open-Source Cognitive Shell for Gitswhy OS

![ReflexCore Logo](assets/logo.png)

[![GitHub stars](https://img.shields.io/github/stars/gitswhy/reflexcore?style=social)](https://github.com/gitswhy/reflexcore/stargazers)
[![Version](https://img.shields.io/badge/version-v1.0.0-green.svg)](https://github.com/gitswhy/reflexcore/releases/tag/v1.0.0)
[![Apache License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/gitswhy/reflexcore/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/gitswhy/reflexcore)](https://github.com/gitswhy/reflexcore/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/gitswhy/reflexcore)](https://github.com/gitswhy/reflexcore/pulls)
[![CI Status](https://github.com/gitswhy/reflexcore/actions/workflows/reflexcore-ci.yml/badge.svg)](https://github.com/gitswhy/reflexcore/actions/workflows/reflexcore-ci.yml)

**Join our community on [Discord](https://discord.com/invite/NuevNNzQwm)!**

## 🌟 What is ReflexCore?

**ReflexCore** is the open-source foundation for Gitswhy OS—a **cognition-native DevSecOps operating system**. It's a lightweight, background-running agent that enhances your shell with real-time monitoring, performance optimization, and secure event logging.

Think of it as your **AI-powered system companion** that runs silently in the background, making your development environment smarter and more responsive.

## ✨ Key Features

### 🧠 **Cognitive Enhancement**
- **Hesitation Detection**: Automatically detects when you pause while typing
- **Cognitive Drift Monitoring**: Tracks your workflow patterns
- **Intent Data Storage**: Securely stores your development intentions

### ⚡ **Performance Optimization**
- **Smart Overclocking**: Automatically tunes system parameters (`scripts/gitswhy_gpuoverclock.sh`)
- **Entropy Flushing**: Clears system sludge and caches (`scripts/gitswhy_quantumflush.sh`)
- **Resource Management**: Kills zombie processes and cleans temp files (`scripts/gitswhy_autoclean.sh`)

### 🔒 **Security & Privacy**
- **Encrypted Vaults**: PBKDF2-encrypted event storage (`gitswhy_vault_manager.py`)
- **Secure Logging**: All sensitive data is encrypted at rest
- **Privacy-First**: Runs locally, no data sent to external servers

### 🛠️ **Developer Experience**
- **Unified CLI**: Manage everything with simple commands (`cli/gitswhy_cli.py`)
- **Background Operation**: Zero interference with your workflow
- **Cross-Platform**: Works on Linux and macOS

## 🖥️ **Platform Compatibility**

### **Linux and macOS (Full Support) ✅**
```bash
# ✅ ALL COMMANDS WORK - Full ReflexCore Experience
# Shell scripts (native support)
./scripts/gitswhy_initiate.sh
./modules/gitswhy_coremirror.sh monitor
./scripts/gitswhy_gpuoverclock.sh

# Python commands (cross-platform)
python3 cli/gitswhy_cli.py init
python3 cli/gitswhy_cli.py mirror

# System tests
./test_all.sh
python3 -m pytest testall.py -v
```

**Why Shell Scripts Work:**
- **Native Bash**: Both Linux and macOS have bash as default shell
- **Unix Commands**: All commands (`ps`, `kill`, `find`, `grep`) are standard Unix
- **System Integration**: Full access to system processes and resources
- **File Permissions**: Unix-style permissions work natively

### **Windows (Limited Support) ⚠️**
```bash
# ❌ Shell scripts DON'T work natively
# ✅ Python commands work perfectly
python cli/gitswhy_cli.py init
python cli/gitswhy_cli.py mirror
python -m pytest testall.py -v

# For shell scripts, use WSL (Windows Subsystem for Linux)
wsl ./scripts/gitswhy_initiate.sh
```

**Windows Limitations:**
- **No Native Bash**: Windows doesn't have bash by default
- **Different System Calls**: Windows uses different system APIs
- **Limited Features**: Shell-based features need WSL or Git Bash

## 🚀 Quick Start (30 seconds)

### **Linux and macOS (Complete Installation)**
```bash
# Clone and install
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore
pip install -r requirements.txt

# Make scripts executable (Linux/macOS only)
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# Initialize and start monitoring
python3 cli/gitswhy_cli.py init
python3 cli/gitswhy_cli.py mirror
```

### **Windows (Python Only)**
```bash
# Clone and install
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore
pip install -r requirements.txt

# Initialize and start monitoring (Python only)
python cli/gitswhy_cli.py init
python cli/gitswhy_cli.py mirror
```

That's it! ReflexCore is now running in the background, enhancing your development experience.

## 🏗️ Architecture Overview

```
ReflexCore
├── Core Monitoring (modules/gitswhy_coremirror.sh)
├── Performance Optimization (scripts/gitswhy_gpuoverclock.sh)
├── System Maintenance (scripts/gitswhy_autoclean.sh)
├── Entropy Management (scripts/gitswhy_quantumflush.sh)
├── System Initialization (scripts/gitswhy_initiate.sh)
├── Vault Synchronization (scripts/gitswhy_vaultsync.sh)
├── Secure Storage (gitswhy_vault_manager.py)
└── Unified Interface (cli/gitswhy_cli.py)
```

## 🎯 Perfect For

- **Developers** who want smarter, more responsive systems
- **DevOps Engineers** who need automated system optimization
- **Security Professionals** who require secure event logging
- **Productivity Enthusiasts** who want AI-enhanced workflows
- **Open Source Contributors** who want to build the future of DevSecOps

## 🔧 Technical Highlights

- **100% CI/CD Compliant**: All tests pass, ShellCheck compliant
- **Production Ready**: Battle-tested with comprehensive error handling
- **Modular Architecture**: Easy to extend and customize
- **Apache 2.0 Licensed**: Open source with patent protection
- **Cross-Platform**: Linux and macOS support

## 📖 Documentation

- **[Installation Guide](docs/INSTALL.md)** - Complete setup instructions
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to ReflexCore
- **[Security Policy](SECURITY.md)** - Security reporting and guidelines
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Community guidelines

## 🧪 Testing & Validation

### **Step-by-Step Testing Guide**

1. **Initialize the System**
   ```bash
   python3 cli/gitswhy_cli.py init
   ```

2. **Start Core Monitoring**
   ```bash
   python3 cli/gitswhy_cli.py mirror
   ```

3. **Test Keystroke Monitoring**
   ```bash
   # Check script status first
   modules/gitswhy_coremirror.sh status
   
   # Run the monitoring script in background
   modules/gitswhy_coremirror.sh monitor &
   
   # Test by typing with pauses (in the same terminal)
   echo "Type something with a pause..." # Pause 2-3 seconds while typing
   
   # Check logs
   cat ~/.gitswhy/events.log
   
   # Or use the built-in logs command
   modules/gitswhy_coremirror.sh logs
   ```

4. **Test Performance Optimization**
   ```bash
   # Run GPU overclocking (if supported)
   scripts/gitswhy_gpuoverclock.sh
   
   # Run system cleanup
   scripts/gitswhy_autoclean.sh
   ```

5. **Test Entropy Management**
   ```bash
   # Flush system entropy
   scripts/gitswhy_quantumflush.sh
   ```

## 🔧 CLI Commands

```bash
# Initialize ReflexCore
python3 cli/gitswhy_cli.py init

# Start keystroke monitoring
python3 cli/gitswhy_cli.py mirror

# Run system optimization
python3 cli/gitswhy_cli.py overclock

# Flush system entropy
python3 cli/gitswhy_cli.py flush

# Clean system resources
python3 cli/gitswhy_cli.py clean

# Sync vault data
python3 cli/gitswhy_cli.py syncvault

# Show vault contents
python3 cli/gitswhy_cli.py showvault

# Check system status
python3 cli/gitswhy_cli.py status

# Stop all services
python3 cli/gitswhy_cli.py stop

# Restart services
python3 cli/gitswhy_cli.py restart
```

## 🧠 Core Mirror Script Usage

The `modules/gitswhy_coremirror.sh` script provides advanced keystroke monitoring and hesitation detection:

```bash
# Check script status and configuration
modules/gitswhy_coremirror.sh status

# Start keystroke monitoring (default)
modules/gitswhy_coremirror.sh monitor

# Run test monitoring sequence
modules/gitswhy_coremirror.sh test

# View recent monitoring events
modules/gitswhy_coremirror.sh logs

# Run in background
modules/gitswhy_coremirror.sh monitor &
```

### **Core Mirror Features**
- **Real-time Keystroke Monitoring**: Tracks every keystroke with microsecond precision
- **Hesitation Detection**: Automatically detects typing pauses (configurable threshold)
- **JSON Logging**: Structured logging to `~/.gitswhy/events.log`
- **Configuration-Driven**: All settings configurable via `config/gitswhy_config.yaml`
- **Background Operation**: Can run silently in the background
- **Cross-Platform**: Works on Linux and macOS systems

### **Configuration Options**
```yaml
# In config/gitswhy_config.yaml
core_mirror:
  keystroke_monitoring_enabled: true
  hesitation_threshold: 2.0  # seconds
  hesitation_alerts_enabled: true
  json_logging_enabled: true
```

## 🚨 Quick Troubleshooting

- **Permission denied**: Ensure scripts are executable: `chmod +x scripts/*.sh modules/*.sh`
- **Missing dependencies**: Install with `pip install -r requirements.txt`
- **Vault not created**: Run `python3 cli/gitswhy_cli.py syncvault`
- **Logs location**: Check `~/.gitswhy/` or `/root/.gitswhy/` for logs and vault files
- **Config errors**: Verify `config/gitswhy_config.yaml` exists and has required fields

## 📊 Current Status

- ✅ **v1.0.0 Released**: Stable and production-ready
- ✅ **All Tests Passing**: 100% CI/CD compliance
- ✅ **Documentation Complete**: Comprehensive guides and examples
- ✅ **Community Ready**: Discord server, contribution guidelines
- 🔄 **Active Development**: Regular updates and improvements

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

### **License Change Note**
This project has switched from the MIT License to the Apache License 2.0 to provide better patent protection for contributors and users while remaining fully permissive.

- **Why the Change?** Apache 2.0 includes explicit patent grants, protecting against patent litigation risks in an open-core model
- **Impact on Users/Contributors**: Minimal—it's still permissive (you can use, modify, and distribute freely)
- **Questions?** Open an issue or check the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for details

---

**Ready to experience the future of development?** 🚀

**Get started now:** https://github.com/gitswhy/reflexcore

**Join our community:** https://discord.com/invite/NuevNNzQwm

---

*ReflexCore v1.0.0 - Making development smarter, one keystroke at a time.* 