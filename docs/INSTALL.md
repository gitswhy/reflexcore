# ReflexCore Installation Guide

![ReflexCore Logo](../assets/logo.png)

**ReflexCore v1.0.0** - Complete installation and setup guide for the cognition-native DevSecOps operating system.

---

## 🖥️ **Platform Compatibility**

### **Linux and macOS (Full Support) ✅**
- **All Features Available**: Shell scripts + Python commands
- **Native Performance**: Direct system integration
- **Complete Functionality**: Keystroke monitoring, system optimization, vault operations

### **Windows (Limited Support) ⚠️**
- **Python Commands Only**: CLI and vault operations work
- **Shell Scripts**: Require WSL (Windows Subsystem for Linux)
- **Limited Features**: System optimization features need Linux environment

---

## 📋 **Prerequisites**

### **System Requirements**
- **Operating System**: Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+) or macOS (10.15+)
- **Python**: 3.7 or higher
- **Bash**: 4.0 or higher (Linux/macOS only)
- **Memory**: 50MB RAM minimum
- **Disk Space**: 100MB free space

### **Required Software**
```bash
# Check Python version
python3 --version  # Should be 3.7+

# Check Bash version (Linux/macOS only)
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

### **Linux and macOS (Complete Installation)**
```bash
# 1. Clone the repository
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore

# 2. Install dependencies
pip install -r requirements.txt

# 3. Make scripts executable (Linux/macOS only)
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# 4. Initialize ReflexCore
python3 cli/gitswhy_cli.py init

# 5. Start monitoring
python3 cli/gitswhy_cli.py mirror
```

### **Windows (Python Only)**
```bash
# 1. Clone the repository
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore

# 2. Install dependencies
pip install -r requirements.txt

# 3. Initialize ReflexCore (Python only)
python cli/gitswhy_cli.py init

# 4. Start monitoring (Python only)
python cli/gitswhy_cli.py mirror
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

### **Step 3: Set Up Script Permissions (Linux/macOS Only)**

```bash
# Make all scripts executable
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# Verify permissions
ls -la scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py
```

**Note**: This step is not required on Windows as shell scripts don't run natively.

### **Step 4: Install System Dependencies (Linux Only)**

For full functionality on Ubuntu/Debian systems:

```bash
# Install bc calculator for advanced calculations
sudo apt update
sudo apt install bc

# Verify installation
bc --version
```

**Note**: macOS usually has `bc` pre-installed. Windows users can skip this step.

### **Step 5: Initialize ReflexCore**

```bash
# Initialize the system
python3 cli/gitswhy_cli.py init  # Linux/macOS
python cli/gitswhy_cli.py init   # Windows
```

---

## 🧪 **Testing & Validation**

### **Python Tests (All Platforms)**
```bash
# Run all Python tests
python3 -m pytest testall.py -v  # Linux/macOS
python -m pytest testall.py -v   # Windows
```

### **System Tests (Linux/macOS Only)**
```bash
# Run full system test suite (requires sudo)
sudo ./test_all.sh

# Run individual script tests
modules/keystroke_monitor_v2.sh status
modules/keystroke_monitor_v2.sh test
```

### **Windows System Tests (WSL Required)**
```bash
# Install WSL if not already installed
wsl --install

# Run system tests in WSL
wsl sudo ./test_all.sh
```

---

## 🎯 **Platform-Specific Features**

### **Linux and macOS Features**
- ✅ **Shell Scripts**: All `.sh` scripts work natively
- ✅ **System Optimization**: GPU overclocking, entropy management
- ✅ **Process Management**: Zombie process cleanup, resource optimization
- ✅ **Keystroke Monitoring**: Real-time monitoring with hesitation detection
- ✅ **Background Services**: Full background process management

### **Windows Features**
- ✅ **Python CLI**: All CLI commands work perfectly
- ✅ **Vault Operations**: Encrypted storage and retrieval
- ✅ **Configuration**: YAML configuration management
- ❌ **Shell Scripts**: Don't work natively (need WSL)
- ❌ **System Optimization**: Limited without WSL

---

## 🚀 **Quick Start Commands**

### **Linux and macOS (Full Experience)**
```bash
# Initialize system
python3 cli/gitswhy_cli.py init

# Start monitoring
python3 cli/gitswhy_cli.py mirror

# System optimization
python3 cli/gitswhy_cli.py overclock

# System cleanup
python3 cli/gitswhy_cli.py clean

# Check status
python3 cli/gitswhy_cli.py status

# Test keystroke monitoring
modules/keystroke_monitor_v2.sh monitor &

# Check logs
cat ~/.gitswhy/events.log
```

### **Windows (Python Only)**
```bash
# Initialize system
python cli/gitswhy_cli.py init

# Start monitoring
python cli/gitswhy_cli.py mirror

# Check status
python cli/gitswhy_cli.py status

# Show vault contents
python cli/gitswhy_cli.py showvault
```

---

## 🔧 **Configuration**

### **Main Configuration File**
```bash
# Edit configuration
nano config/gitswhy_config.yaml  # Linux/macOS
notepad config/gitswhy_config.yaml  # Windows
```

### **Key Configuration Options**
```yaml
# Core monitoring settings
core_mirror:
  keystroke_monitoring_enabled: true
  hesitation_threshold: 2.0  # seconds

# Performance settings
performance:
  overclock_enabled: true
  swappiness: 10

# Security settings
security:
  secure_vault: true
  encryption_enabled: true
```

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Permission Denied (Linux/macOS)**
```bash
# Fix script permissions
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py
```

#### **Python Not Found**
```bash
# Install Python 3.7+
# Ubuntu/Debian
sudo apt update && sudo apt install python3 python3-pip

# macOS
brew install python3

# Windows
# Download from python.org
```

#### **Missing Dependencies**
```bash
# Install Python dependencies
pip install -r requirements.txt

# Install system dependencies (Linux)
sudo apt install bc  # Ubuntu/Debian
```

#### **Vault Not Created**
```bash
# Create vault manually
python3 cli/gitswhy_cli.py syncvault  # Linux/macOS
python cli/gitswhy_cli.py syncvault   # Windows
```

### **Platform-Specific Issues**

#### **Linux Issues**
- **No bc calculator**: `sudo apt install bc`
- **Permission issues**: Check sudo privileges
- **Service conflicts**: Stop conflicting services

#### **macOS Issues**
- **Gatekeeper warnings**: Allow in System Preferences
- **Permission prompts**: Grant terminal permissions
- **Homebrew required**: Install with `brew install python3`

#### **Windows Issues**
- **Shell scripts not working**: Use WSL or Git Bash
- **Python path issues**: Add Python to PATH
- **Permission errors**: Run as administrator if needed

---

## 📊 **Installation Verification**

### **Linux and macOS Verification**
```bash
# Check Python installation
python3 --version

# Check script permissions
ls -la scripts/*.sh modules/*.sh

# Test CLI
python3 cli/gitswhy_cli.py --help

# Test shell scripts
./modules/keystroke_monitor_v2.sh status

# Run tests
python3 -m pytest testall.py -v
./test_all.sh
```

### **Windows Verification**
```bash
# Check Python installation
python --version

# Test CLI
python cli/gitswhy_cli.py --help

# Run Python tests
python -m pytest testall.py -v
```

---

## 🎉 **Success Indicators**

### **Linux and macOS Success**
- ✅ All CLI commands work
- ✅ All shell scripts execute without errors
- ✅ System tests pass
- ✅ Keystroke monitoring active
- ✅ Vault operations successful

### **Windows Success**
- ✅ All CLI commands work
- ✅ Python tests pass
- ✅ Vault operations successful
- ⚠️ Shell scripts require WSL for full functionality

---

## 📞 **Support**

### **Getting Help**
- **GitHub Issues**: [Report problems](https://github.com/gitswhy/reflexcore/issues)
- **Discord Community**: [Join for support](https://discord.com/invite/NuevNNzQwm)
- **Documentation**: [Complete guides](docs/)

### **Platform-Specific Support**
- **Linux**: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch
- **macOS**: 10.15 (Catalina) and later
- **Windows**: Limited support (WSL recommended)

---

**Ready to get started?** Follow the quick installation guide above and join our community! 🚀 