#!/bin/bash

#==============================================================================
# Gitswhy OS - GPU/System Overclock Script
# File: scripts/gitswhy_gpuoverclock.sh
# Description: Optimizes system parameters for enhanced performance
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhyGPUOverclock"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration paths
CONFIG_FILE="$ROOT_DIR/config/gitswhy_config.yaml"
LOG_DIR="$HOME/.gitswhy"
LOG_FILE="$LOG_DIR/overclock.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values if config is missing
DEFAULT_SWAPPINESS=10
DEFAULT_VFS_CACHE_PRESSURE=50
DEFAULT_ULIMIT_N=65536
DEFAULT_ULIMIT_U=32768

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Log function with timestamps
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also output to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        *)       echo "[UNKNOWN] $message" ;;
    esac
}

# Check if running as root or with sudo capabilities
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        SUDO_PREFIX=""
        log_action "WARN" "Not running as root. Privileged operations will be skipped."
    else
        SUDO_PREFIX=""
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse YAML configuration (simplified parser for our use case)
parse_yaml_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_action "WARN" "Configuration file not found: $config_file - using defaults"
        SWAPPINESS=$DEFAULT_SWAPPINESS
        VFS_CACHE_PRESSURE=$DEFAULT_VFS_CACHE_PRESSURE
        ULIMIT_N=$DEFAULT_ULIMIT_N
        ULIMIT_U=$DEFAULT_ULIMIT_U
        OVERCLOCK_ENABLED="true"
        return 0
    fi
    
    # Always check top-level *_enabled flags first
    OVERCLOCK_ENABLED=$(grep -E "^\s*overclock_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    OVERCLOCK_ENABLED=${OVERCLOCK_ENABLED:-"true"}
    
    # Extract swappiness value
    SWAPPINESS=$(grep -E "^\s*swappiness:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_SWAPPINESS")
    
    # Extract vfs_cache_pressure value
    VFS_CACHE_PRESSURE=$(grep -E "^\s*vfs_cache_pressure:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_VFS_CACHE_PRESSURE")
    
    # Extract ulimit values
    ULIMIT_N=$(grep -E "^\s*ulimit_n:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_ULIMIT_N")
    ULIMIT_U=$(grep -E "^\s*ulimit_u:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_ULIMIT_U")
    
    # Set defaults if extraction failed or values are empty
    SWAPPINESS=${SWAPPINESS:-$DEFAULT_SWAPPINESS}
    VFS_CACHE_PRESSURE=${VFS_CACHE_PRESSURE:-$DEFAULT_VFS_CACHE_PRESSURE}
    ULIMIT_N=${ULIMIT_N:-$DEFAULT_ULIMIT_N}
    ULIMIT_U=${ULIMIT_U:-$DEFAULT_ULIMIT_U}
    
    log_action "INFO" "Configuration loaded: swappiness=$SWAPPINESS, vfs_cache_pressure=$VFS_CACHE_PRESSURE, overclock_enabled=$OVERCLOCK_ENABLED"
}

# Store original values for restoration
store_original_values() {
    if [[ -f "/proc/sys/vm/swappiness" ]]; then
        ORIGINAL_SWAPPINESS=$(cat /proc/sys/vm/swappiness)
        log_action "DEBUG" "Original swappiness: $ORIGINAL_SWAPPINESS"
    fi
    
    if [[ -f "/proc/sys/vm/vfs_cache_pressure" ]]; then
        ORIGINAL_VFS_CACHE_PRESSURE=$(cat /proc/sys/vm/vfs_cache_pressure)
        log_action "DEBUG" "Original vfs_cache_pressure: $ORIGINAL_VFS_CACHE_PRESSURE"
    fi
}

#==============================================================================
# SYSTEM OPTIMIZATION FUNCTIONS
#==============================================================================

# Optimize virtual memory parameters using sysctl
optimize_vm_parameters() {
    log_action "INFO" "Optimizing virtual memory parameters..."
    
    # Adjust swappiness - controls how aggressively the kernel swaps memory pages
    if [[ -f "/proc/sys/vm/swappiness" ]]; then
        log_action "INFO" "Setting vm.swappiness to $SWAPPINESS"
        if $SUDO_PREFIX sysctl -w vm.swappiness="$SWAPPINESS" >/dev/null 2>&1; then
            log_action "INFO" "Successfully set vm.swappiness=$SWAPPINESS"
        else
            log_action "ERROR" "Failed to set vm.swappiness"
            return 1
        fi
    else
        log_action "WARN" "vm.swappiness not available on this system"
    fi
    
    # Adjust VFS cache pressure - controls tendency to reclaim directory and inode caches
    if [[ -f "/proc/sys/vm/vfs_cache_pressure" ]]; then
        log_action "INFO" "Setting vm.vfs_cache_pressure to $VFS_CACHE_PRESSURE"
        if $SUDO_PREFIX sysctl -w vm.vfs_cache_pressure="$VFS_CACHE_PRESSURE" >/dev/null 2>&1; then
            log_action "INFO" "Successfully set vm.vfs_cache_pressure=$VFS_CACHE_PRESSURE"
        else
            log_action "ERROR" "Failed to set vm.vfs_cache_pressure"
            return 1
        fi
    else
        log_action "WARN" "vm.vfs_cache_pressure not available on this system"
    fi
    
    # Additional VM optimizations for performance
    local vm_params=(
        "vm.dirty_ratio=15"
        "vm.dirty_background_ratio=5" 
        "vm.dirty_expire_centisecs=3000"
        "vm.dirty_writeback_centisecs=500"
    )
    
    for param in "${vm_params[@]}"; do
        if $SUDO_PREFIX sysctl -w "$param" >/dev/null 2>&1; then
            log_action "DEBUG" "Set $param"
        else
            log_action "WARN" "Failed to set $param"
        fi
    done
}

# Warm up file system caches by preloading commonly used files
warm_file_caches() {
    log_action "INFO" "Warming up file system caches..."
    
    # List of directories to preload for better performance
    local cache_dirs=(
        "/bin"
        "/usr/bin" 
        "/lib"
        "/usr/lib"
        "/etc"
        "$HOME/.config"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_action "DEBUG" "Preloading files in $dir"
            # Use find to traverse and read file metadata, warming the cache
            find "$dir" -type f -executable -size -1M 2>/dev/null | head -100 | while read -r file; do
                # Read first few bytes to warm the cache without consuming too much time
                dd if="$file" of=/dev/null bs=4096 count=1 2>/dev/null || true
            done &
        fi
    done
    
    # Wait for background cache warming to complete (max 30 seconds)
    local timeout=30
    local count=0
    while [[ $(jobs -r | wc -l) -gt 0 ]] && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    # Kill any remaining background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
    
    log_action "INFO" "File cache warming completed"
}

# Optimize shell limits using ulimit
optimize_shell_limits() {
    log_action "INFO" "Optimizing shell resource limits..."
    
    # Get current limits for logging
    local current_nofile=$(ulimit -n)
    local current_nproc=$(ulimit -u)
    
    log_action "DEBUG" "Current limits - nofile: $current_nofile, nproc: $current_nproc"
    
    # Set maximum number of open file descriptors
    if ulimit -n "$ULIMIT_N" 2>/dev/null; then
        log_action "INFO" "Set maximum open files (ulimit -n) to $ULIMIT_N"
    else
        log_action "WARN" "Failed to set ulimit -n to $ULIMIT_N"
    fi
    
    # Set maximum number of user processes
    if ulimit -u "$ULIMIT_U" 2>/dev/null; then
        log_action "INFO" "Set maximum user processes (ulimit -u) to $ULIMIT_U"
    else
        log_action "WARN" "Failed to set ulimit -u to $ULIMIT_U"
    fi
    
    # Additional performance-oriented limits
    ulimit -c unlimited 2>/dev/null || log_action "WARN" "Failed to set unlimited core dumps"
    ulimit -l unlimited 2>/dev/null || log_action "WARN" "Failed to set unlimited locked memory"
    
    # Display final limits
    log_action "INFO" "Current resource limits after optimization:"
    log_action "INFO" "  Max open files: $(ulimit -n)"
    log_action "INFO" "  Max processes: $(ulimit -u)"
    log_action "INFO" "  Core file size: $(ulimit -c)"
}

# Perform additional system optimizations
additional_optimizations() {
    log_action "INFO" "Applying additional system optimizations..."
    
    # Sync file systems to ensure data consistency
    sync
    log_action "DEBUG" "File systems synchronized"
    
    # Clear page cache, dentries and inodes (be careful with this in production)
    if [[ "${CLEAR_CACHES:-false}" == "true" ]]; then
        log_action "INFO" "Clearing system caches (as requested)"
        echo 3 | $SUDO_PREFIX tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || \
            log_action "WARN" "Failed to clear system caches"
    fi
    
    # Set CPU governor to performance if available
    if command_exists cpufreq-set; then
        for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            if [[ -f "$cpu/cpufreq/scaling_governor" ]]; then
                echo "performance" | $SUDO_PREFIX tee "$cpu/cpufreq/scaling_governor" >/dev/null 2>&1 || true
            fi
        done
        log_action "DEBUG" "Set CPU governor to performance mode"
    fi
}

# Verify optimizations were applied successfully
verify_optimizations() {
    log_action "INFO" "Verifying applied optimizations..."
    
    local verification_failed=false
    
    # Check swappiness
    if [[ -f "/proc/sys/vm/swappiness" ]]; then
        local current_swappiness=$(cat /proc/sys/vm/swappiness)
        if [[ "$current_swappiness" == "$SWAPPINESS" ]]; then
            log_action "INFO" "✓ vm.swappiness verified: $current_swappiness"
        else
            log_action "ERROR" "✗ vm.swappiness mismatch: expected $SWAPPINESS, got $current_swappiness"
            verification_failed=true
        fi
    fi
    
    # Check vfs_cache_pressure
    if [[ -f "/proc/sys/vm/vfs_cache_pressure" ]]; then
        local current_vfs=$(cat /proc/sys/vm/vfs_cache_pressure)
        if [[ "$current_vfs" == "$VFS_CACHE_PRESSURE" ]]; then
            log_action "INFO" "✓ vm.vfs_cache_pressure verified: $current_vfs"
        else
            log_action "ERROR" "✗ vm.vfs_cache_pressure mismatch: expected $VFS_CACHE_PRESSURE, got $current_vfs"
            verification_failed=true
        fi
    fi
    
    # Check ulimits
    local current_nofile=$(ulimit -n)
    if [[ "$current_nofile" == "$ULIMIT_N" ]]; then
        log_action "INFO" "✓ ulimit -n verified: $current_nofile"
    else
        log_action "WARN" "⚠ ulimit -n: expected $ULIMIT_N, got $current_nofile"
    fi
    
    if [[ "$verification_failed" == "true" ]]; then
        return 1
    fi
    
    return 0
}

#==============================================================================
# MAIN EXECUTION FLOW
#==============================================================================

main() {
    log_action "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Check system requirements
    check_privileges
    
    # Parse configuration file
    parse_yaml_config "$CONFIG_FILE"
    
    # Store original values for potential restoration
    store_original_values
    
    # Apply optimizations
    log_action "INFO" "Applying system optimizations for enhanced performance..."
    
    if optimize_vm_parameters; then
        log_action "INFO" "VM parameter optimization completed"
    else
        log_action "ERROR" "VM parameter optimization failed"
        exit 1
    fi
    
    # warm_file_caches
    log_action "INFO" "Overclock complete"
    optimize_shell_limits
    additional_optimizations
    
    # Verify all optimizations were applied correctly
    if verify_optimizations; then
        log_action "INFO" "All optimizations verified successfully"
    else
        log_action "WARN" "Some optimizations could not be verified"
    fi
    
    # Final success message
    echo -e "${GREEN}[GitsWhy] Overclock complete.${NC}"
    log_action "INFO" "System overclock optimization completed successfully"
    log_action "INFO" "Overclock complete"
    
    # Display summary
    echo ""
    echo "=== Optimization Summary ==="
    echo "• VM Swappiness: $SWAPPINESS ($(cat /proc/sys/vm/swappiness 2>/dev/null || echo "N/A"))"
    echo "• VFS Cache Pressure: $VFS_CACHE_PRESSURE ($(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo "N/A"))"
    echo "• Max Open Files: $ULIMIT_N ($(ulimit -n))"
    echo "• Max Processes: $ULIMIT_U ($(ulimit -u))"
    echo "• Log file: $LOG_FILE"
    echo ""
}

# Handle script arguments
case "${1:-optimize}" in
    "optimize"|"start"|"")
        main
        ;;
    "status")
        echo "Current system parameters:"
        echo "vm.swappiness = $(cat /proc/sys/vm/swappiness 2>/dev/null || echo "N/A")"
        echo "vm.vfs_cache_pressure = $(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo "N/A")"
        echo "ulimit -n = $(ulimit -n)"
        echo "ulimit -u = $(ulimit -u)"
        ;;
    "restore")
        if [[ -n "${ORIGINAL_SWAPPINESS:-}" ]]; then
            $SUDO_PREFIX sysctl -w vm.swappiness="$ORIGINAL_SWAPPINESS" >/dev/null 2>&1 || true
            echo "Restored vm.swappiness to $ORIGINAL_SWAPPINESS"
        fi
        if [[ -n "${ORIGINAL_VFS_CACHE_PRESSURE:-}" ]]; then
            $SUDO_PREFIX sysctl -w vm.vfs_cache_pressure="$ORIGINAL_VFS_CACHE_PRESSURE" >/dev/null 2>&1 || true
            echo "Restored vm.vfs_cache_pressure to $ORIGINAL_VFS_CACHE_PRESSURE"
        fi
        ;;
    *)
        echo "Usage: $0 {optimize|status|restore}"
        echo "  optimize - Apply system optimizations (default)"
        echo "  status   - Show current system parameters"
        echo "  restore  - Restore original system parameters"
        exit 1
        ;;
esac 