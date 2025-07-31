#!/bin/bash

# ReflexCore Validation System
# Provides comprehensive validation for all components

set -euo pipefail

# Validation configuration
VALIDATION_LOG_FILE="${VALIDATION_LOG_FILE:-$HOME/.gitswhy/validation.log}"
STRICT_MODE="${STRICT_MODE:-false}"

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validation logging
log_validation() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$VALIDATION_LOG_FILE")"
    
    # Log to file
    echo "[$timestamp] [VALIDATION] [$level] [ctx:$context] $message" >> "$VALIDATION_LOG_FILE"
    
    # Console output
    case "$level" in
        "PASS")  echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
    esac
    
    # Update counters
    case "$level" in
        "PASS") ((VALIDATION_PASSED++)) ;;
        "FAIL") ((VALIDATION_FAILED++)) ;;
        "WARN") ((VALIDATION_WARNINGS++)) ;;
    esac
}

# Validate file existence and permissions
validate_file() {
    local file_path="$1"
    local context="${2:-}"
    local required="${3:-false}"
    
    if [[ ! -f "$file_path" ]]; then
        if [[ "$required" == "true" ]]; then
            log_validation "FAIL" "Required file missing: $file_path" "$context"
            return 1
        else
            log_validation "WARN" "Optional file missing: $file_path" "$context"
            return 0
        fi
    fi
    
    if [[ ! -r "$file_path" ]]; then
        log_validation "FAIL" "File not readable: $file_path" "$context"
        return 1
    fi
    
    if [[ "$file_path" == *.sh ]] && [[ ! -x "$file_path" ]]; then
        log_validation "WARN" "Script not executable: $file_path" "$context"
    fi
    
    log_validation "PASS" "File validated: $file_path" "$context"
    return 0
}

# Validate directory structure
validate_directory() {
    local dir_path="$1"
    local context="${2:-}"
    local required="${3:-false}"
    
    if [[ ! -d "$dir_path" ]]; then
        if [[ "$required" == "true" ]]; then
            log_validation "FAIL" "Required directory missing: $dir_path" "$context"
            return 1
        else
            log_validation "WARN" "Optional directory missing: $dir_path" "$context"
            return 0
        fi
    fi
    
    if [[ ! -r "$dir_path" ]]; then
        log_validation "FAIL" "Directory not readable: $dir_path" "$context"
        return 1
    fi
    
    if [[ ! -w "$dir_path" ]]; then
        log_validation "WARN" "Directory not writable: $dir_path" "$context"
    fi
    
    log_validation "PASS" "Directory validated: $dir_path" "$context"
    return 0
}

# Validate configuration file
validate_config() {
    local config_file="$1"
    local context="${2:-}"
    
    if [[ ! -f "$config_file" ]]; then
        log_validation "FAIL" "Configuration file missing: $config_file" "$context"
        return 1
    fi
    
    # Check if it's valid YAML
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
            log_validation "FAIL" "Invalid YAML in configuration: $config_file" "$context"
            return 1
        fi
    fi
    
    # Check for required configuration keys
    local required_keys=("overclock_enabled" "vault_sync_enabled" "entropy_flush_enabled")
    for key in "${required_keys[@]}"; do
        if ! grep -q "^[[:space:]]*${key}:" "$config_file" 2>/dev/null; then
            log_validation "WARN" "Missing configuration key: $key" "$context"
        fi
    done
    
    log_validation "PASS" "Configuration validated: $config_file" "$context"
    return 0
}

# Validate Python environment
validate_python() {
    local context="${1:-}"
    
    if ! command -v python3 >/dev/null 2>&1; then
        log_validation "FAIL" "Python3 not found" "$context"
        return 1
    fi
    
    local python_version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    log_validation "INFO" "Python version: $python_version" "$context"
    
    # Check required packages
    local required_packages=("click" "cryptography" "pyyaml")
    for pkg in "${required_packages[@]}"; do
        if ! python3 -c "import $pkg" 2>/dev/null; then
            log_validation "FAIL" "Missing Python package: $pkg" "$context"
            return 1
        fi
    done
    
    log_validation "PASS" "Python environment validated" "$context"
    return 0
}

# Validate system commands
validate_commands() {
    local context="${1:-}"
    
    # Required commands
    local required_commands=("bash" "grep" "awk" "sed" "cat" "echo" "date")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_validation "FAIL" "Missing required command: $cmd" "$context"
            return 1
        fi
    done
    
    # Optional but recommended commands
    local optional_commands=("bc" "timeout" "stty" "dd" "rsync" "cpufreq-set")
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_validation "WARN" "Missing optional command: $cmd" "$context"
        fi
    done
    
    log_validation "PASS" "System commands validated" "$context"
    return 0
}

# Validate system resources
validate_resources() {
    local context="${1:-}"
    local issues=0
    
    # Check disk space
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    if [[ $disk_usage -gt 95 ]]; then
        log_validation "FAIL" "Critical disk usage: ${disk_usage}%" "$context"
        ((issues++))
    elif [[ $disk_usage -gt 90 ]]; then
        log_validation "WARN" "High disk usage: ${disk_usage}%" "$context"
    fi
    
    # Check memory
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}' 2>/dev/null || echo "0")
    if [[ $mem_usage -gt 95 ]]; then
        log_validation "FAIL" "Critical memory usage: ${mem_usage}%" "$context"
        ((issues++))
    elif [[ $mem_usage -gt 90 ]]; then
        log_validation "WARN" "High memory usage: ${mem_usage}%" "$context"
    fi
    
    # Check load average
    if command -v uptime >/dev/null 2>&1; then
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "0")
        local cpu_cores
        cpu_cores=$(nproc 2>/dev/null || echo "1")
        local load_per_core
        load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc -l 2>/dev/null || echo "0")
        
        if (( $(echo "$load_per_core > 5.0" | bc -l 2>/dev/null || echo "0") )); then
            log_validation "FAIL" "Critical system load: ${load_per_core} per core" "$context"
            ((issues++))
        elif (( $(echo "$load_per_core > 2.0" | bc -l 2>/dev/null || echo "0") )); then
            log_validation "WARN" "High system load: ${load_per_core} per core" "$context"
        fi
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_validation "PASS" "System resources validated" "$context"
        return 0
    else
        return 1
    fi
}

# Validate ReflexCore structure
validate_reflexcore_structure() {
    local context="${1:-}"
    local root_dir="${2:-.}"
    local issues=0
    
    log_validation "INFO" "Validating ReflexCore structure" "$context"
    
    # Required directories
    local required_dirs=("scripts" "modules" "config" "cli")
    for dir in "${required_dirs[@]}"; do
        if ! validate_directory "$root_dir/$dir" "$context" "true"; then
            ((issues++))
        fi
    done
    
    # Required files
    local required_files=(
        "scripts/gitswhy_initiate.sh"
        "config/gitswhy_config.yaml"
        "gitswhy_vault_manager.py"
        "cli/gitswhy_cli.py"
    )
    for file in "${required_files[@]}"; do
        if ! validate_file "$root_dir/$file" "$context" "true"; then
            ((issues++))
        fi
    done
    
    # Optional but recommended files
    local optional_files=(
        "README.md"
        "requirements.txt"
        "LICENSE"
        "SECURITY.md"
    )
    for file in "${optional_files[@]}"; do
        validate_file "$root_dir/$file" "$context" "false"
    done
    
    if [[ $issues -eq 0 ]]; then
        log_validation "PASS" "ReflexCore structure validated" "$context"
        return 0
    else
        log_validation "FAIL" "ReflexCore structure validation failed" "$context"
        return 1
    fi
}

# Validate script permissions
validate_permissions() {
    local context="${1:-}"
    local root_dir="${2:-.}"
    local issues=0
    
    log_validation "INFO" "Validating script permissions" "$context"
    
    # Find all shell scripts
    local scripts
    mapfile -t scripts < <(find "$root_dir" -name "*.sh" -type f 2>/dev/null || true)
    
    for script in "${scripts[@]}"; do
        if [[ ! -x "$script" ]]; then
            log_validation "WARN" "Script not executable: $script" "$context"
            ((issues++))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_validation "PASS" "Script permissions validated" "$context"
        return 0
    else
        log_validation "WARN" "Some scripts need executable permissions" "$context"
        return 0  # Not a critical failure
    fi
}

# Comprehensive validation
validate_all() {
    local context="${1:-main}"
    local root_dir="${2:-.}"
    
    log_validation "INFO" "Starting comprehensive validation" "$context"
    
    # Reset counters
    VALIDATION_PASSED=0
    VALIDATION_FAILED=0
    VALIDATION_WARNINGS=0
    
    local overall_success=true
    
    # Run all validations
    validate_commands "$context" || overall_success=false
    validate_python "$context" || overall_success=false
    validate_resources "$context" || overall_success=false
    validate_reflexcore_structure "$context" "$root_dir" || overall_success=false
    validate_permissions "$context" "$root_dir"
    validate_config "$root_dir/config/gitswhy_config.yaml" "$context" || overall_success=false
    
    # Summary
    log_validation "INFO" "Validation summary:" "$context"
    log_validation "INFO" "  Passed: $VALIDATION_PASSED" "$context"
    log_validation "INFO" "  Failed: $VALIDATION_FAILED" "$context"
    log_validation "INFO" "  Warnings: $VALIDATION_WARNINGS" "$context"
    
    if [[ "$overall_success" == "true" ]]; then
        log_validation "PASS" "All validations passed" "$context"
        return 0
    else
        log_validation "FAIL" "Some validations failed" "$context"
        return 1
    fi
}

# Export functions
export -f log_validation validate_file validate_directory validate_config
export -f validate_python validate_commands validate_resources
export -f validate_reflexcore_structure validate_permissions validate_all 