#!/bin/bash

# ReflexCore System Diagnostic Script
# This script checks what commands and tools are available on the system

set -euo pipefail

echo "🔍 ReflexCore System Diagnostic"
echo "=================================="

# Check operating system
echo -e "\n📋 Operating System:"
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"

# Check if we're on Windows
if [[ "$(uname -s)" =~ MINGW|MSYS|CYGWIN ]]; then
    echo "⚠️  Running on Windows (Git Bash/Cygwin/MSYS)"
    IS_WINDOWS=true
else
    echo "✅ Running on Linux/Unix"
    IS_WINDOWS=false
fi

# Check Python
echo -e "\n🐍 Python Environment:"
if command -v python3 >/dev/null 2>&1; then
    echo "✅ python3: $(python3 --version 2>&1)"
else
    echo "❌ python3: Not found"
fi

if command -v python >/dev/null 2>&1; then
    echo "✅ python: $(python --version 2>&1)"
else
    echo "❌ python: Not found"
fi

# Check required system commands
echo -e "\n🔧 System Commands:"
REQUIRED_COMMANDS=(
    "bash"
    "nohup"
    "ps"
    "kill"
    "sleep"
    "sync"
    "mkdir"
    "rm"
    "cp"
    "mv"
    "find"
    "grep"
    "awk"
    "sed"
    "cat"
    "echo"
    "date"
    "whoami"
    "pwd"
    "cd"
)

OPTIONAL_COMMANDS=(
    "bc"
    "dd"
    "stty"
    "rsync"
    "cpufreq-set"
    "top"
    "free"
    "df"
    "sudo"
    "curl"
    "wget"
)

echo "Required commands:"
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  ✅ $cmd"
    else
        echo "  ❌ $cmd (MISSING)"
    fi
done

echo -e "\nOptional commands (for advanced features):"
for cmd in "${OPTIONAL_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  ✅ $cmd"
    else
        echo "  ⚠️  $cmd (Not available)"
    fi
done

# Check Python packages
echo -e "\n📦 Python Packages:"
PYTHON_PACKAGES=("click" "cryptography" "pyyaml")
for pkg in "${PYTHON_PACKAGES[@]}"; do
    if python3 -c "import $pkg" 2>/dev/null; then
        echo "  ✅ $pkg"
    else
        echo "  ❌ $pkg (Not installed)"
    fi
done

# Check file permissions
echo -e "\n📁 File Permissions:"
SCRIPTS=(
    "scripts/gitswhy_initiate.sh"
    "scripts/gitswhy_gpuoverclock.sh"
    "scripts/gitswhy_quantumflush.sh"
    "scripts/gitswhy_autoclean.sh"
    "scripts/gitswhy_vaultsync.sh"
    "modules/gitswhy_coremirror.sh"
    "gitswhy_vault_manager.py"
    "cli/gitswhy_cli.py"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            echo "  ✅ $script (executable)"
        else
            echo "  ⚠️  $script (not executable)"
        fi
    else
        echo "  ❌ $script (not found)"
    fi
done

# Check configuration
echo -e "\n⚙️  Configuration:"
if [[ -f "config/gitswhy_config.yaml" ]]; then
    echo "  ✅ config/gitswhy_config.yaml"
else
    echo "  ❌ config/gitswhy_config.yaml (missing)"
fi

# Check directories
echo -e "\n📂 Directories:"
DIRS=("scripts" "modules" "config" "cli" "docs" "assets")
for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "  ✅ $dir/"
    else
        echo "  ❌ $dir/ (missing)"
    fi
done

# Summary and recommendations
echo -e "\n📊 Summary:"
echo "=================================="

if [[ "$IS_WINDOWS" == true ]]; then
    echo "⚠️  WINDOWS ENVIRONMENT DETECTED"
    echo ""
    echo "Many ReflexCore features require Linux system commands that are not"
    echo "available on Windows. The following features will NOT work:"
    echo "  • GPU overclocking (requires cpufreq-set)"
    echo "  • System monitoring (requires top, free, df)"
    echo "  • Keystroke monitoring (requires stty, dd, bc)"
    echo "  • Vault sync (requires rsync)"
    echo ""
    echo "✅ What WILL work:"
    echo "  • Basic initialization"
    echo "  • Configuration management"
    echo "  • Logging (basic)"
    echo "  • Python-based vault management"
    echo ""
    echo "💡 Recommendations:"
    echo "  1. Use WSL (Windows Subsystem for Linux) for full functionality"
    echo "  2. Run on a Linux virtual machine"
    echo "  3. Use only the Python components on Windows"
else
    echo "✅ LINUX ENVIRONMENT DETECTED"
    echo ""
    echo "Most ReflexCore features should work. Check the missing commands"
    echo "above and install them if needed:"
    echo ""
    echo "Ubuntu/Debian: sudo apt install bc rsync cpufrequtils"
    echo "CentOS/RHEL: sudo yum install bc rsync cpufrequtils"
    echo "Arch: sudo pacman -S bc rsync cpufrequtils"
fi

echo -e "\n🚀 Next Steps:"
echo "1. Install missing Python packages: pip install click cryptography pyyaml"
echo "2. Make scripts executable: chmod +x scripts/*.sh modules/*.sh"
echo "3. Run basic test: python3 cli/gitswhy_cli.py init"
echo "4. For full testing on Linux: sudo ./test_all.sh" 