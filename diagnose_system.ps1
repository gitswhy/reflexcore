# ReflexCore System Diagnostic Script (PowerShell)
# This script checks what commands and tools are available on the Windows system

Write-Host "ReflexCore System Diagnostic" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check operating system
Write-Host "`nOperating System:" -ForegroundColor Yellow
Write-Host "OS: $($env:OS)"
Write-Host "Architecture: $($env:PROCESSOR_ARCHITECTURE)"
Write-Host "Windows Version: $(Get-ComputerInfo | Select-Object -ExpandProperty WindowsProductName)"

# Check if we're on Windows
Write-Host "Running on Windows" -ForegroundColor Yellow

# Check Python
Write-Host "`nPython Environment:" -ForegroundColor Yellow
try {
    $python3Version = python3 --version 2>&1
    Write-Host "python3: $python3Version" -ForegroundColor Green
} catch {
    Write-Host "python3: Not found" -ForegroundColor Red
}

try {
    $pythonVersion = python --version 2>&1
    Write-Host "python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "python: Not found" -ForegroundColor Red
}

# Check required system commands
Write-Host "`nSystem Commands:" -ForegroundColor Yellow
$REQUIRED_COMMANDS = @(
    "python", "python3", "pip", "pip3"
)

$OPTIONAL_COMMANDS = @(
    "bash", "git", "wsl", "docker"
)

Write-Host "Required commands:"
foreach ($cmd in $REQUIRED_COMMANDS) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "  $cmd" -ForegroundColor Green
    } else {
        Write-Host "  $cmd (MISSING)" -ForegroundColor Red
    }
}

Write-Host "`nOptional commands (for advanced features):"
foreach ($cmd in $OPTIONAL_COMMANDS) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "  $cmd" -ForegroundColor Green
    } else {
        Write-Host "  $cmd (Not available)" -ForegroundColor Yellow
    }
}

# Check Python packages
Write-Host "`nPython Packages:" -ForegroundColor Yellow
$PYTHON_PACKAGES = @("click", "cryptography", "pyyaml")
foreach ($pkg in $PYTHON_PACKAGES) {
    try {
        python3 -c "import $pkg" 2>$null
        Write-Host "  $pkg" -ForegroundColor Green
    } catch {
        Write-Host "  $pkg (Not installed)" -ForegroundColor Red
    }
}

# Check file existence
Write-Host "`nFiles:" -ForegroundColor Yellow
$SCRIPTS = @(
    "scripts/gitswhy_initiate.sh",
    "scripts/gitswhy_gpuoverclock.sh", 
    "scripts/gitswhy_quantumflush.sh",
    "scripts/gitswhy_autoclean.sh",
    "scripts/gitswhy_vaultsync.sh",
    "modules/gitswhy_coremirror.sh",
    "gitswhy_vault_manager.py",
    "cli/gitswhy_cli.py"
)

foreach ($script in $SCRIPTS) {
    if (Test-Path $script) {
        Write-Host "  $script" -ForegroundColor Green
    } else {
        Write-Host "  $script (not found)" -ForegroundColor Red
    }
}

# Check configuration
Write-Host "`nConfiguration:" -ForegroundColor Yellow
if (Test-Path "config/gitswhy_config.yaml") {
    Write-Host "  config/gitswhy_config.yaml" -ForegroundColor Green
} else {
    Write-Host "  config/gitswhy_config.yaml (missing)" -ForegroundColor Red
}

# Check directories
Write-Host "`nDirectories:" -ForegroundColor Yellow
$DIRS = @("scripts", "modules", "config", "cli", "docs", "assets")
foreach ($dir in $DIRS) {
    if (Test-Path $dir) {
        Write-Host "  $dir/" -ForegroundColor Green
    } else {
        Write-Host "  $dir/ (missing)" -ForegroundColor Red
    }
}

# Summary and recommendations
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

Write-Host "WINDOWS ENVIRONMENT DETECTED" -ForegroundColor Yellow
Write-Host ""
Write-Host "Many ReflexCore features require Linux system commands that are not" -ForegroundColor White
Write-Host "available on Windows. The following features will NOT work:" -ForegroundColor White
Write-Host "  GPU overclocking (requires cpufreq-set)" -ForegroundColor Red
Write-Host "  System monitoring (requires top, free, df)" -ForegroundColor Red
Write-Host "  Keystroke monitoring (requires stty, dd, bc)" -ForegroundColor Red
Write-Host "  Vault sync (requires rsync)" -ForegroundColor Red
Write-Host ""
Write-Host "What WILL work:" -ForegroundColor Green
Write-Host "  Basic initialization" -ForegroundColor Green
Write-Host "  Configuration management" -ForegroundColor Green
Write-Host "  Logging (basic)" -ForegroundColor Green
Write-Host "  Python-based vault management" -ForegroundColor Green
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "  1. Use WSL (Windows Subsystem for Linux) for full functionality" -ForegroundColor White
Write-Host "  2. Run on a Linux virtual machine" -ForegroundColor White
Write-Host "  3. Use only the Python components on Windows" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Install missing Python packages: pip install click cryptography pyyaml" -ForegroundColor White
Write-Host "2. Test Python components: python3 cli/gitswhy_cli.py init" -ForegroundColor White
Write-Host "3. For full functionality, use WSL or a Linux VM" -ForegroundColor White 