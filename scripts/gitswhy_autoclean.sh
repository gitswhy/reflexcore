#!/bin/bash

#==============================================================================
# Gitswhy OS - Auto Clean Script
# File: scripts/gitswhy_autoclean.sh
# Description: Kills zombie processes, clears old caches, and frees resources
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhyAutoClean"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration paths
CONFIG_FILE="$ROOT_DIR/config/gitswhy_config.yaml"
LOG_DIR="$HOME/.gitswhy"
LOG_FILE="$LOG_DIR/events.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default values if config is missing
DEFAULT_ZOMBIE_KILL_ENABLED=true
DEFAULT_CACHE_CLEAR_ENABLED=true
DEFAULT_MEMORY_FREE_ENABLED=true
DEFAULT_CACHE_AGE_DAYS=7
DEFAULT_MEMORY_THRESHOLD=80
DEFAULT_TEMP_CLEAN_ENABLED=true

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Log function with timestamps
log_action() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    echo "[$timestamp] [CLEAN] [$level] $message" >> "$LOG_FILE"
    
    # Also output to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "CLEAN") echo -e "${PURPLE}[CLEAN]${NC} $message" ;;
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

# Parse YAML configuration
parse_yaml_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_action "WARN" "Configuration file not found: $config_file - using defaults"
        ZOMBIE_KILL_ENABLED=$DEFAULT_ZOMBIE_KILL_ENABLED
        CACHE_CLEAR_ENABLED=$DEFAULT_CACHE_CLEAR_ENABLED
        MEMORY_FREE_ENABLED=$DEFAULT_MEMORY_FREE_ENABLED
        TEMP_CLEAN_ENABLED=$DEFAULT_TEMP_CLEAN_ENABLED
        CACHE_AGE_DAYS=$DEFAULT_CACHE_AGE_DAYS
        MEMORY_THRESHOLD=$DEFAULT_MEMORY_THRESHOLD
        return 0
    fi
    
    # Always check top-level *_enabled flags first
    ZOMBIE_KILL_ENABLED=$(grep -E "^\s*zombie_kill_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    CACHE_CLEAR_ENABLED=$(grep -E "^\s*cache_clear_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    MEMORY_FREE_ENABLED=$(grep -E "^\s*memory_free_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    TEMP_CLEAN_ENABLED=$(grep -E "^\s*temp_clean_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    
    # Set defaults if extraction failed or values are empty
    ZOMBIE_KILL_ENABLED=${ZOMBIE_KILL_ENABLED:-"true"}
    CACHE_CLEAR_ENABLED=${CACHE_CLEAR_ENABLED:-"true"}
    MEMORY_FREE_ENABLED=${MEMORY_FREE_ENABLED:-"true"}
    TEMP_CLEAN_ENABLED=${TEMP_CLEAN_ENABLED:-"true"}
    
    # Sanitize enabled flags
    ZOMBIE_KILL_ENABLED=$(echo "$ZOMBIE_KILL_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    CACHE_CLEAR_ENABLED=$(echo "$CACHE_CLEAR_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    MEMORY_FREE_ENABLED=$(echo "$MEMORY_FREE_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    TEMP_CLEAN_ENABLED=$(echo "$TEMP_CLEAN_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    # Debug output for config flags
    echo "[DEBUG] zombie_kill_enabled=$ZOMBIE_KILL_ENABLED" >&2
    echo "[DEBUG] cache_clear_enabled=$CACHE_CLEAR_ENABLED" >&2
    echo "[DEBUG] memory_free_enabled=$MEMORY_FREE_ENABLED" >&2
    echo "[DEBUG] temp_clean_enabled=$TEMP_CLEAN_ENABLED" >&2
    
    # Extract other configuration values
    CACHE_AGE_DAYS=$(grep -E "^\s*cache_age_days:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_CACHE_AGE_DAYS")
    MEMORY_THRESHOLD=$(grep -E "^\s*memory_threshold_percent:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_MEMORY_THRESHOLD")
    
    log_action "INFO" "Configuration loaded: Zombies=$ZOMBIE_KILL_ENABLED, Cache=$CACHE_CLEAR_ENABLED, Memory=$MEMORY_FREE_ENABLED, Temp=$TEMP_CLEAN_ENABLED"
}

# Display system status before cleaning
show_system_status() {
    log_action "INFO" "System status before auto-clean:"
    
    # Check for zombie processes
    local zombie_count
    zombie_count=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
    log_action "DEBUG" "Zombie processes found: $zombie_count"
    
    # Check memory usage
    if command_exists free; then
        local mem_usage
        mem_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
        log_action "DEBUG" "Memory usage: ${mem_usage}%"
    fi
    
    # Check cache directories size
    local cache_size=0
    if [[ -d "$HOME/.cache" ]]; then
        cache_size=$(du -sm "$HOME/.cache" 2>/dev/null | cut -f1 || echo "0")
        log_action "DEBUG" "User cache size: ${cache_size}MB"
    fi
    
    # Check temp directory size
    local temp_size
    temp_size=$(du -sm /tmp 2>/dev/null | cut -f1 || echo "0")
    log_action "DEBUG" "Temp directory size: ${temp_size}MB"
}

#==============================================================================
# ZOMBIE PROCESS MANAGEMENT
#==============================================================================

# Kill zombie processes by targeting their parent processes
kill_zombie_processes() {
    if [[ "$ZOMBIE_KILL_ENABLED" != "true" ]]; then
        log_action "INFO" "Zombie process killing disabled in configuration"
        return 0
    fi
    
    log_action "CLEAN" "Scanning for zombie processes..."
    
    # Find zombie processes and their parent PIDs
    local zombie_pids
    zombie_pids=($(ps -eo pid,ppid,stat,cmd | awk '$3=="Z" {print $1}' 2>/dev/null || true))
    local parent_pids
    parent_pids=($(ps -eo pid,ppid,stat,cmd | awk '$3=="Z" {print $2}' 2>/dev/null || true))
    
    if [[ ${#zombie_pids[@]} -eq 0 ]]; then
        log_action "INFO" "✓ No zombie processes found"
        return 0
    fi
    
    log_action "WARN" "Found ${#zombie_pids[@]} zombie process(es)"
    
    # Kill parent processes to reap zombies
    for i in "${!zombie_pids[@]}"; do
        local zombie_pid="${zombie_pids[$i]}"
        local parent_pid="${parent_pids[$i]}"
        
        if [[ -n "$parent_pid" && "$parent_pid" != "1" ]]; then
            log_action "INFO" "Killing parent process $parent_pid to reap zombie $zombie_pid"
            
            # First try gentle termination
            if kill -TERM "$parent_pid" 2>/dev/null; then
                sleep 2
                # Check if zombie is gone
                if ! kill -0 "$zombie_pid" 2>/dev/null; then
                    log_action "INFO" "✓ Zombie process $zombie_pid reaped successfully"
                    continue
                fi
            fi
            
            # Force kill if gentle termination failed
            if kill -KILL "$parent_pid" 2>/dev/null; then
                log_action "WARN" "Force killed parent process $parent_pid"
            else
                log_action "ERROR" "Failed to kill parent process $parent_pid"
            fi
        else
            log_action "WARN" "Zombie $zombie_pid has init as parent - cannot safely kill"
        fi
    done
    
    # Verify zombies were cleaned up
    sleep 2
    local remaining_zombies
    remaining_zombies=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
    if [[ $remaining_zombies -eq 0 ]]; then
        log_action "INFO" "✓ All zombie processes successfully cleaned"
    else
        log_action "WARN" "⚠ $remaining_zombies zombie process(es) still remain"
    fi
}

#==============================================================================
# CACHE CLEANING FUNCTIONS
#==============================================================================

# Clear old caches based on age thresholds
clear_old_caches() {
    if [[ "$CACHE_CLEAR_ENABLED" != "true" ]]; then
        log_action "INFO" "Cache clearing disabled in configuration"
        return 0
    fi
    MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
    log_action "CLEAN" "Clearing old caches (age threshold: $CACHE_AGE_DAYS days)..."
    
    local cleaned_count=0
    local cleaned_size=0
    
    # Clear user cache directories
    local cache_dirs=(
        "$HOME/.cache"
        "$HOME/.thumbnails"
        "$HOME/.local/share/Trash"
        "/tmp"
        "/var/tmp"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ ! -d "$cache_dir" ]]; then
            continue
        fi
        
        log_action "DEBUG" "Cleaning cache directory: $cache_dir"
        
        # Find and remove old files
        local old_files
        old_files=$(find "$cache_dir" -type f -mtime "+$CACHE_AGE_DAYS" 2>/dev/null | wc -l)
        old_files=${old_files:-0}
        if [[ $old_files -gt 0 ]]; then
            local dir_size_before
            dir_size_before=$(du -sm "$cache_dir" 2>/dev/null | cut -f1 || echo "0")
            dir_size_before=${dir_size_before:-0}
            
            # Remove old files with permission error handling
            if find "$cache_dir" -type f -mtime "+$CACHE_AGE_DAYS" -delete 2>/dev/null; then
                local dir_size_after
                dir_size_after=$(du -sm "$cache_dir" 2>/dev/null | cut -f1 || echo "0")
                dir_size_after=${dir_size_after:-0}
                local size_freed
                size_freed=$((dir_size_before - dir_size_after))
                
                cleaned_count=$((cleaned_count + old_files))
                cleaned_size=$((cleaned_size + size_freed))
                
                log_action "INFO" "✓ Cleaned $old_files files from $cache_dir (freed ${size_freed}MB)"
            else
                log_action "WARN" "Permission denied cleaning some files in $cache_dir"
            fi
        fi
        
        # Remove empty directories
        find "$cache_dir" -type d -empty -delete 2>/dev/null || true
    done
    
    # Clear system caches if permissions allow
    cleaned_size=${cleaned_size:-0}
    local mem_percent
    mem_percent=$(free | grep Mem | awk '{printf "%0.f", ($3/$2)*100}' || echo "0")
    mem_percent=${mem_percent:-0}
    MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
    echo "[DEBUG] MEMORY_THRESHOLD=$MEMORY_THRESHOLD" >&2
    if [[ "$cleaned_size" -gt 100 ]]; then
        log_action "INFO" "Clearing system page cache..."
        sync
        if echo 1 | $SUDO_PREFIX tee /proc/sys/vm/drop_caches >/dev/null 2>&1; then
            log_action "INFO" "✓ System page cache cleared"
        else
            log_action "WARN" "Failed to clear system page cache (permission denied)"
        fi
    elif [[ "$mem_percent" =~ ^[0-9]+$ && "$MEMORY_THRESHOLD" =~ ^[0-9]+$ && $mem_percent -gt $MEMORY_THRESHOLD ]]; then
        log_action "INFO" "Clearing system page cache..."
        sync
        if echo 1 | $SUDO_PREFIX tee /proc/sys/vm/drop_caches >/dev/null 2>&1; then
            log_action "INFO" "✓ System page cache cleared"
        else
            log_action "WARN" "Failed to clear system page cache (permission denied)"
        fi
    fi
    
    log_action "CLEAN" "Cache cleaning completed: $cleaned_count files removed, ${cleaned_size}MB freed"
}

#==============================================================================
# RESOURCE FREEING FUNCTIONS
#==============================================================================

# Free system resources and memory
free_system_resources() {
    if [[ "$MEMORY_FREE_ENABLED" != "true" ]]; then
        log_action "INFO" "Memory freeing disabled in configuration"
        return 0
    fi
    MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
    log_action "CLEAN" "Freeing system resources..."
    
    # Check current memory usage
    if command_exists free; then
        local mem_before
        mem_before=$(free -m | grep Mem | awk '{print $3}')
        local mem_total
        mem_total=$(free -m | grep Mem | awk '{print $2}')
        mem_before=${mem_before:-0}
        mem_total=${mem_total:-1}
        local mem_percent_before
        mem_percent_before=$(( (mem_before * 100) / mem_total ))
        
        log_action "DEBUG" "Memory usage before cleanup: ${mem_percent_before}% (${mem_before}MB/${mem_total}MB)"
        
        if [[ "$mem_percent_before" =~ ^[0-9]+$ && "$MEMORY_THRESHOLD" =~ ^[0-9]+$ && $mem_percent_before -gt $MEMORY_THRESHOLD ]]; then
            MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
            echo "[DEBUG] MEMORY_THRESHOLD=$MEMORY_THRESHOLD" >&2
            log_action "WARN" "High memory usage detected (${mem_percent_before}% > ${MEMORY_THRESHOLD}%)"
            
            # Clear all caches aggressively
            log_action "INFO" "Performing aggressive cache clearing..."
            sync
            
            # Clear PageCache, dentries and inodes
            if echo 3 | $SUDO_PREFIX tee /proc/sys/vm/drop_caches >/dev/null 2>&1; then
                log_action "INFO" "✓ Cleared PageCache, dentries, and inodes"
            else
                log_action "WARN" "Failed to clear system caches (permission denied)"
            fi
            
            # Clear swap if it's being used heavily
            local swap_used
            swap_used=$(free -m | grep Swap | awk '{print $3}')
            local swap_total
            swap_total=$(free -m | grep Swap | awk '{print $2}')
            
            if [[ $swap_total -gt 0 && $swap_used -gt 100 ]]; then
                log_action "INFO" "Clearing swap space..."
                if $SUDO_PREFIX swapoff -a 2>/dev/null && $SUDO_PREFIX swapon -a 2>/dev/null; then
                    log_action "INFO" "✓ Swap space cleared and re-enabled"
                else
                    log_action "WARN" "Failed to clear swap space"
                fi
            fi
        fi
        
        # Check memory after cleanup
        sleep 2
        local mem_after
        mem_after=$(free -m | grep Mem | awk '{print $3}')
        mem_after=${mem_after:-0}
        local mem_percent_after
        mem_percent_after=$(( (mem_after * 100) / mem_total ))
        local mem_freed
        mem_freed=$((mem_before - mem_after))
        
        log_action "INFO" "Memory usage after cleanup: ${mem_percent_after}% (freed ${mem_freed}MB)"
    fi
    
    # Compact memory if available
    if [[ -f "/proc/sys/vm/compact_memory" ]]; then
        log_action "DEBUG" "Triggering memory compaction..."
        echo 1 | $SUDO_PREFIX tee /proc/sys/vm/compact_memory >/dev/null 2>&1 || true
    fi
    
    log_action "CLEAN" "Resource freeing completed"
}

#==============================================================================
# TEMPORARY FILE CLEANUP
#==============================================================================

# Clean temporary files and directories
clean_temp_files() {
    if [[ "$TEMP_CLEAN_ENABLED" != "true" ]]; then
        log_action "INFO" "Temporary file cleaning disabled in configuration"
        return 0
    fi
    
    log_action "CLEAN" "Cleaning temporary files..."
    
    local temp_dirs=(
        "/tmp"
        "/var/tmp"
        "$HOME/.tmp"
    )
    
    local cleaned_files=0
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ ! -d "$temp_dir" ]]; then
            continue
        fi
        
        # Clean old temporary files (older than 1 day)
        local old_temp_files
        old_temp_files=$(find "$temp_dir" -type f -mtime +1 2>/dev/null | wc -l)
        if [[ $old_temp_files -gt 0 ]]; then
            if find "$temp_dir" -type f -mtime +1 -delete 2>/dev/null; then
                cleaned_files=$((cleaned_files + old_temp_files))
                log_action "INFO" "✓ Cleaned $old_temp_files temporary files from $temp_dir"
            else
                log_action "WARN" "Permission denied cleaning some temp files in $temp_dir"
            fi
        fi
        
        # Clean empty directories in temp
        find "$temp_dir" -type d -empty -delete 2>/dev/null || true
    done
    
    # Clean core dumps
    if find /tmp -name "core.*" -type f -delete 2>/dev/null; then
        log_action "DEBUG" "Removed core dump files"
    fi
    
    log_action "CLEAN" "Temporary file cleaning completed: $cleaned_files files removed"
}

#==============================================================================
# VERIFICATION FUNCTIONS
#==============================================================================

# Verify cleaning was successful
verify_cleaning_success() {
    log_action "INFO" "Verifying auto-clean success..."
    
    local verification_passed=true
    
    # Check zombie processes
    local zombies_after
    zombies_after=$(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')
    if [[ $zombies_after -eq 0 ]]; then
        log_action "INFO" "✓ No zombie processes remaining"
    else
        log_action "WARN" "⚠ $zombies_after zombie process(es) still present"
    fi
    
    # Check memory usage
    if command_exists free; then
        local mem_usage
        mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
        mem_usage=${mem_usage:-0}
        MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
        if [[ "$mem_usage" =~ ^[0-9]+$ && "$MEMORY_THRESHOLD" =~ ^[0-9]+$ && $mem_usage -lt $MEMORY_THRESHOLD ]]; then
            log_action "INFO" "✓ Memory usage within threshold (${mem_usage}% = ${MEMORY_THRESHOLD}%)"
            verification_passed=false
        fi
    fi
    
    # Check disk space
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    log_action "DEBUG" "Root partition usage: ${disk_usage}%"
    
    if [[ "$verification_passed" == "true" ]]; then
        log_action "INFO" "✓ Auto-clean verification completed successfully"
        return 0
    else
        log_action "WARN" "⚠ Some verification checks failed"
        return 1
    fi
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
    
    # Display system status before cleaning
    show_system_status
    
    log_action "CLEAN" "Initiating auto-clean sequence..."
    
    # Execute cleaning operations
    kill_zombie_processes
    clear_old_caches
    free_system_resources
    clean_temp_files
    
    # Verify cleaning success
    if verify_cleaning_success; then
        log_action "INFO" "Auto-clean completed successfully"
    else
        log_action "WARN" "Auto-clean completed with some warnings"
    fi
    
    # Final success message
    echo -e "${GREEN}[GitsWhy] Clean complete.${NC}"
    log_action "INFO" "Auto-clean operation completed"
    
    # Display summary
    echo ""
    echo "=== Auto Clean Summary ==="
    echo "• Zombie Processes: $([ "$ZOMBIE_KILL_ENABLED" = "true" ] && echo "✓ Cleaned" || echo "✗ Skipped")"
    echo "• Old Caches: $([ "$CACHE_CLEAR_ENABLED" = "true" ] && echo "✓ Cleared" || echo "✗ Skipped")"
    echo "• Memory Resources: $([ "$MEMORY_FREE_ENABLED" = "true" ] && echo "✓ Freed" || echo "✗ Skipped")"
    echo "• Temporary Files: $([ "$TEMP_CLEAN_ENABLED" = "true" ] && echo "✓ Cleaned" || echo "✗ Skipped")"
    if command_exists free; then
        echo "• Current Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", ($3/$2)*100}')"
    fi
    echo "• Log file: $LOG_FILE"
    echo ""
}

# Handle script arguments
case "${1:-clean}" in
    "clean"|"start"|"")
        main
        ;;
    "status")
        echo "Current system status:"
        echo "Zombie Processes: $(ps aux | awk '$8 ~ /^Z/ { count++ } END { print count+0 }')"
        if command_exists free; then
            echo "Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", ($3/$2)*100}')"
        fi
        echo "Root Disk Usage: $(df / | tail -1 | awk '{print $5}')"
        if [[ -d "$HOME/.cache" ]]; then
            echo "Cache Size: $(du -sh "$HOME/.cache" 2>/dev/null | cut -f1 || echo "0")"
        fi
        echo "Temp Size: $(du -sh /tmp 2>/dev/null | cut -f1 || echo "0")"
        ;;
    "test")
        echo "Running auto-clean test sequence..."
        main
        ;;
    *)
        echo "Usage: $0 {clean|status|test}"
        echo "  clean  - Perform auto cleanup (default)"
        echo "  status - Show current system status"
        echo "  test   - Run test cleanup sequence"
        exit 1
        ;;
esac 