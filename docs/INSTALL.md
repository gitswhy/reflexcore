# ReflexCore Installation Guide

![ReflexCore Logo](../assets/logo.png)

**ReflexCore v1.0.0** - Complete installation and setup guide for the cognition-native DevSecOps operating system.

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Installation](#quick-installation)
- [Detailed Installation](#detailed-installation)
- [Configuration](#configuration)
- [Testing & Validation](#testing--validation)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)

---

## 🎯 Prerequisites

### **System Requirements**
- **Operating System**: Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+) or macOS 10.15+
- **Python**: 3.7 or higher
- **Bash**: 4.0 or higher
- **Git**: Latest version
- **Memory**: 512MB RAM minimum, 2GB recommended
- **Disk Space**: 100MB free space

### **Required Software**
```bash
# Check Python version
python3 --version  # Should be 3.7+

# Check Bash version
bash --version     # Should be 4.0+

# Check Git
git --version      # Any recent version
```

### **Optional (for full functionality)**
- **sudo privileges** for system-level optimizations
- **bc** calculator for advanced calculations: `sudo apt install bc` (Ubuntu/Debian)
- **dd** for raw input handling (usually pre-installed)

---

## ⚡ Quick Installation

For experienced users who want to get started immediately:

```bash
# 1. Clone the repository
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore

# 2. Install dependencies
pip install -r requirements.txt

# 3. Make scripts executable
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# 4. Initialize ReflexCore
python3 cli/gitswhy_cli.py init

# 5. Start monitoring
python3 cli/gitswhy_cli.py mirror
```

**That's it!** ReflexCore is now running and monitoring your system.

---

## 📖 Detailed Installation

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore
```

### **Step 2: Install Python Dependencies**

```bash
# Install required Python packages
pip install -r requirements.txt

# Or install manually if needed
pip install click cryptography pyyaml pytest
```

**Required packages:**
- `click`: CLI framework
- `cryptography`: Encryption for vault operations
- `pyyaml`: Configuration file parsing
- `pytest`: Testing framework

### **Step 3: Set Up Script Permissions**

```bash
# Make all scripts executable
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# Verify permissions
ls -la scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py
```

### **Step 4: Install System Dependencies (Optional)**

For full functionality on Ubuntu/Debian systems:

```bash
# Install bc calculator for advanced calculations
sudo apt update
sudo apt install bc

# Verify installation
bc --version
```

### **Step 5: Initialize ReflexCore**

```bash
# Initialize the system
python3 cli/gitswhy_cli.py init

# This will:
# - Create ~/.gitswhy directory
# - Set up configuration files
# - Initialize the vault system
# - Configure logging
```

### **Step 6: Verify Installation**

```bash
# Check system status
python3 cli/gitswhy_cli.py status

# Run test suite
python3 -m pytest testall.py -v
```

---

## ⚙️ Configuration

### **Configuration File Location**
- **Default**: `config/gitswhy_config.yaml`
- **User-specific**: `~/.gitswhy/config.yaml` (if created)

### **Key Configuration Options**

```yaml
# Enable/disable features
overclock_enabled: true
vault_sync_enabled: true
entropy_flush_enabled: true
auto_clean_enabled: true
core_monitor_enabled: true
keystroke_monitoring_enabled: true

# Performance settings
performance:
  swappiness: 10
  vfs_cache_pressure: 50
  max_cpu_temp: 85
  performance_mode: "high"

# Monitoring thresholds
core_mirror:
  hesitation_threshold: 2.0
  hesitation_alerts_enabled: true
  json_logging_enabled: true

# Security settings
vault:
  vault_password: "gitswhy_default_vault_password_2025"
  vault_key_iterations: 100000
```

### **Customizing Configuration**

1. **Copy the default config**:
   ```bash
   cp config/gitswhy_config.yaml ~/.gitswhy/config.yaml
   ```

2. **Edit your config**:
   ```bash
   nano ~/.gitswhy/config.yaml
   ```

3. **Use custom config**:
   ```bash
   python3 cli/gitswhy_cli.py --config ~/.gitswhy/config.yaml init
   ```

---

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
   # Run the monitoring script in background
   modules/gitswhy_coremirror.sh &
   
   # Test by typing with pauses (in the same terminal)
   echo "Type something with a pause..." # Pause 2-3 seconds while typing
   
   # Check logs
   cat ~/.gitswhy/events.log
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

6. **Test Vault Operations**
   ```bash
   # Store test data
   python3 gitswhy_vault_manager.py --config config/gitswhy_config.yaml --vault-file ~/.gitswhy/vault.json --operation store --input-file test_data.json
   
   # Retrieve data
   python3 gitswhy_vault_manager.py --config config/gitswhy_config.yaml --vault-file ~/.gitswhy/vault.json --operation retrieve
   ```

7. **Run Full Test Suite**
   ```bash
   python3 -m pytest testall.py -v
   ```

### **Expected Test Results**

All tests should pass with output similar to:
```
test_vault_store_operation ... ✓ Vault store operation completed successfully
test_vault_retrieve_operation ... ✓ Vault retrieve operation completed successfully
test_vault_analyze_operation ... ✓ Vault analyze operation completed successfully
test_vault_analyze_builtin_operation ... ✓ Vault analyze_builtin operation completed successfully
test_config_file_exists ... ✓ Config file exists: config/gitswhy_config.yaml
test_vault_manager_exists ... ✓ Vault manager script exists: gitswhy_vault_manager.py
```

---

## 💡 Usage Examples

### **Basic Usage**

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
```

### **Advanced Usage**

```bash
# Show vault contents with decryption
python3 cli/gitswhy_cli.py showvault --decrypt --format json

# Sync vault data
python3 cli/gitswhy_cli.py syncvault

# Check system status
python3 cli/gitswhy_cli.py status

# Stop all services
python3 cli/gitswhy_cli.py stop

# Restart services
python3 cli/gitswhy_cli.py restart
```

### **Direct Script Usage**

```bash
# Run individual scripts directly
./scripts/gitswhy_initiate.sh
./scripts/gitswhy_gpuoverclock.sh
./scripts/gitswhy_quantumflush.sh
./scripts/gitswhy_autoclean.sh
./modules/gitswhy_coremirror.sh

# Vault operations
python3 gitswhy_vault_manager.py --help
```

### **Background Operation**

Add to your shell startup file (`.bashrc`, `.zshrc`):

```bash
# Auto-start ReflexCore
source /path/to/reflexcore/scripts/gitswhy_initiate.sh
```

---

## 🚨 Troubleshooting

### **Common Issues**

#### **Permission Denied Errors**
```bash
# Make scripts executable
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# Run with sudo if needed
sudo python3 cli/gitswhy_cli.py init
```

#### **Missing Dependencies**
```bash
# Install Python dependencies
pip install -r requirements.txt

# Install system dependencies (Ubuntu/Debian)
sudo apt update && sudo apt install bc
```

#### **Vault Not Created**
```bash
# Create vault manually
python3 cli/gitswhy_cli.py syncvault

# Check vault directory
ls -la ~/.gitswhy/
```

#### **Configuration Errors**
```bash
# Verify config file exists
ls -la config/gitswhy_config.yaml

# Check config syntax
python3 -c "import yaml; yaml.safe_load(open('config/gitswhy_config.yaml'))"
```

### **Log Locations**

- **Main logs**: `~/.gitswhy/events.log`
- **System logs**: `/var/log/syslog` (Linux)
- **Application logs**: `~/.gitswhy/` directory

### **Debug Mode**

```bash
# Enable verbose output
python3 cli/gitswhy_cli.py --verbose init

# Check script status
python3 cli/gitswhy_cli.py status
```

### **Getting Help**

```bash
# CLI help
python3 cli/gitswhy_cli.py --help
python3 cli/gitswhy_cli.py init --help

# Script help
./scripts/gitswhy_initiate.sh --help
./modules/gitswhy_coremirror.sh --help
```

---

## 🗑️ Uninstallation

### **Complete Removal**

```bash
# Stop all services
python3 cli/gitswhy_cli.py stop

# Remove ReflexCore directory
rm -rf /path/to/reflexcore

# Remove user data (optional)
rm -rf ~/.gitswhy

# Remove from shell startup files
# Edit ~/.bashrc or ~/.zshrc and remove the source line
```

### **Partial Removal**

```bash
# Keep data but remove installation
python3 cli/gitswhy_cli.py stop
# Remove only the installation directory
# Keep ~/.gitswhy for data preservation
```

---

## 📞 Support

### **Getting Help**

- **Documentation**: Check this guide and the main [README.md](../README.md)
- **Issues**: [GitHub Issues](https://github.com/gitswhy/reflexcore/issues)
- **Community**: [Discord Server](https://discord.com/invite/NuevNNzQwm)
- **Security**: [Security Policy](../SECURITY.md)

### **Reporting Issues**

When reporting issues, please include:
- Operating system and version
- Python version
- ReflexCore version
- Error messages and logs
- Steps to reproduce

---

## 🎉 Next Steps

After successful installation:

1. **Explore the CLI**: Try all available commands
2. **Customize Configuration**: Adjust settings in `config/gitswhy_config.yaml`
3. **Join the Community**: Connect on Discord
4. **Contribute**: Check [CONTRIBUTING.md](../CONTRIBUTING.md)
5. **Stay Updated**: Watch the repository for updates

---

**Ready to experience the future of development?** 🚀

**Get started now:** https://github.com/gitswhy/reflexcore

**Join our community:** https://discord.com/invite/NuevNNzQwm

---

*ReflexCore v1.0.0 - Making development smarter, one keystroke at a time.* 