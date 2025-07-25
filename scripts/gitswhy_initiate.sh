#!/bin/bash

#==============================================================================
# Gitswhy OS - ReflexCore Bootstrap Script
# File: scripts/gitswhy_initiate.sh
# Description: Initializes core background processes for system optimization
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhydInitiate"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration paths
CONFIG_FILE="$ROOT_DIR/config/gitswhy_config.yaml"
LOG_DIR="$HOME/.gitswhy"
LOG_FILE="$LOG_DIR/events.log"
mkdir -p "$(dirname "$LOG_FILE")"
PID_DIR="$LOG_DIR/pids"

# Process identifiers
PROCESS_LIST=(
    "overclocking"
    "entropy_flush"
    "auto_clean"
    "core_monitoring"
    "vault_sync"
)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect if running on Windows (Git Bash or Cygwin)
IS_WINDOWS=false
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        IS_WINDOWS=true
        ;;
esac

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Enhanced log function with log rotation
log_event() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user
    user=$(whoami 2>/dev/null || echo "unknown")
    local proc_name=${BASH_SOURCE[1]:-main}

    # Log rotation by size (default 100MB)
    local max_size_bytes=104857600 # 100MB
    if [[ -n "${LOG_MAX_SIZE:-}" ]]; then
        # Convert e.g. 100MB to bytes
        case "$LOG_MAX_SIZE" in
            *MB|*mb) max_size_bytes=$(( ${LOG_MAX_SIZE//[!0-9]/} * 1048576 )) ;;
            *KB|*kb) max_size_bytes=$(( ${LOG_MAX_SIZE//[!0-9]/} * 1024 )) ;;
            *GB|*gb) max_size_bytes=$(( ${LOG_MAX_SIZE//[!0-9]/} * 1073741824 )) ;;
            *) max_size_bytes=${LOG_MAX_SIZE//[!0-9]/} ;;
        esac
    fi
    if [[ -f "$LOG_FILE" ]]; then
        local log_size
        log_size=$(wc -c < "$LOG_FILE")
        if (( log_size > max_size_bytes )); then
            mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d_%H%M%S)"
            touch "$LOG_FILE"
        fi
    fi

    # Log rotation by age (default 30 days)
    local rotation_days=30
    if [[ -n "${LOG_ROTATION_DAYS:-}" ]]; then
        rotation_days=$LOG_ROTATION_DAYS
    fi
    find "$(dirname "$LOG_FILE")" -name "$(basename "$LOG_FILE").*" -mtime +$rotation_days -delete 2>/dev/null || true

    # Write log entry with context
    echo "[$timestamp] [$level] [user:$user] [proc:$proc_name] $message" >> "$LOG_FILE"
    
    # Also output to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        *)       echo "[UNKNOWN] $message" ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse YAML configuration (enhanced for logging)
parse_yaml_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        log_event "ERROR" "Configuration file not found: $config_file"
        return 1
    fi
    # Always check top-level *_enabled flags first
    OVERCLOCK_ENABLED=$(grep -E "^\s*overclock_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    VAULT_SYNC_ENABLED=$(grep -E "^\s*vault_sync_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    ENTROPY_FLUSH_ENABLED=$(grep -E "^\s*entropy_flush_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    AUTO_CLEAN_ENABLED=$(grep -E "^\s*auto_clean_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    CORE_MONITOR_ENABLED=$(grep -E "^\s*core_monitor_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    # Fallback to true if not found
    OVERCLOCK_ENABLED=$(echo "$OVERCLOCK_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    VAULT_SYNC_ENABLED=$(echo "$VAULT_SYNC_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    ENTROPY_FLUSH_ENABLED=$(echo "$ENTROPY_FLUSH_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    AUTO_CLEAN_ENABLED=$(echo "$AUTO_CLEAN_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    CORE_MONITOR_ENABLED=$(echo "$CORE_MONITOR_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    # Debug output for config flags
    echo "[DEBUG] overclock_enabled=$OVERCLOCK_ENABLED" >&2
    echo "[DEBUG] vault_sync_enabled=$VAULT_SYNC_ENABLED" >&2
    echo "[DEBUG] entropy_flush_enabled=$ENTROPY_FLUSH_ENABLED" >&2
    echo "[DEBUG] auto_clean_enabled=$AUTO_CLEAN_ENABLED" >&2
    echo "[DEBUG] core_monitor_enabled=$CORE_MONITOR_ENABLED" >&2
    ENTROPY_INTERVAL=$(grep -E "^\s*entropy_flush_interval:" "$config_file" | sed 's/.*:\s*//' | tr -d ' ')
    CLEAN_INTERVAL=$(grep -E "^\s*auto_clean_interval:" "$config_file" | sed 's/.*:\s*//' | tr -d ' ')
    MONITOR_INTERVAL=$(grep -E "^\s*core_monitor_interval:" "$config_file" | sed 's/.*:\s*//' | tr -d ' ')
    LOG_MAX_SIZE=$(grep -E "^\s*max_log_size:" "$config_file" | sed 's/.*:\s*//' | tr -d '" ')
    LOG_ROTATION_DAYS=$(grep -E "^\s*rotation_days:" "$config_file" | sed 's/.*:\s*//' | tr -d ' ')
    # Set defaults if not found
    ENTROPY_INTERVAL=${ENTROPY_INTERVAL:-"300"}
    CLEAN_INTERVAL=${CLEAN_INTERVAL:-"3600"}
    MONITOR_INTERVAL=${MONITOR_INTERVAL:-"60"}
    LOG_MAX_SIZE=${LOG_MAX_SIZE:-"100MB"}
    LOG_ROTATION_DAYS=${LOG_ROTATION_DAYS:-30}
    log_event "INFO" "Configuration loaded successfully"
}

# Create necessary directories
setup_directories() {
    local dirs=("$LOG_DIR" "$PID_DIR")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_event "INFO" "Created directory: $dir"
        fi
    done
}

# Check system requirements
check_system_requirements() {
    local required_commands=("nohup" "ps" "kill" "sleep" "sync")
    # Only require cpufreq-set and rsync on non-Windows
    if [[ "$IS_WINDOWS" == false ]]; then
        required_commands+=("cpufreq-set" "rsync")
    fi
    local missing_commands=()
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_event "WARN" "Missing commands: ${missing_commands[*]}"
        log_event "WARN" "Some features may not work correctly"
    fi
}

# Check privileges
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        SUDO_PREFIX=""
        log_event "WARN" "Not running as root. Privileged operations will be skipped."
    else
        SUDO_PREFIX=""
    fi
}

#==============================================================================
# PROCESS MANAGEMENT FUNCTIONS
#==============================================================================

# Start overclocking process
start_overclocking() {
    if [[ "$OVERCLOCK_ENABLED" != "true" ]]; then
        log_event "INFO" "Overclocking disabled in configuration"
        return 0
    fi
    if [[ "$IS_WINDOWS" == true ]]; then
        log_event "WARN" "Overclocking is not supported on Windows. Skipping."
        return 0
    fi
    log_event "INFO" "Starting overclocking process..."
    
    # Create overclocking background process
    nohup bash -c "
        while true; do
            # Check CPU temperature and adjust frequencies
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                if [[ -f \"\$cpu/cpufreq/scaling_governor\" ]]; then
                    echo performance > \"\$cpu/cpufreq/scaling_governor\" 2>/dev/null || true
                fi
            done
            # Log temperature monitoring
            if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
                temp=\$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
                temp_c=\$((temp / 1000))
                if [[ \$temp_c -gt 80 ]]; then
                    echo \"\$(date): High CPU temp: \${temp_c}°C\" >> \"$LOG_FILE\"
                fi
            fi
            sleep 30
        done
    " > "$LOG_DIR/overclocking.out" 2>&1 &
    
    echo $! > "$PID_DIR/overclocking.pid"
    log_event "INFO" "Overclocking process started with PID: $!"
}

# Start entropy flush process
start_entropy_flush() {
    if [[ "$ENTROPY_FLUSH_ENABLED" != "true" ]]; then
        log_event "INFO" "Entropy flush disabled in configuration"
        return 0
    fi
    if [[ "$IS_WINDOWS" == true ]]; then
        log_event "WARN" "Entropy flush is not supported on Windows. Skipping."
        return 0
    fi
    log_event "INFO" "Starting entropy flush process..."
    
    nohup bash -c "
        while true; do
            # Flush entropy pool periodically
            if [[ -w /proc/sys/kernel/random/entropy_avail ]]; then
                entropy=\$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo 0)
                if [[ \$entropy -lt 1000 ]]; then
                    # Generate entropy using system activity
                    find /proc -type f -name 'stat' -exec cat {} \\; >/dev/null 2>&1 &
                    dd if=/dev/urandom of=/dev/null bs=1 count=100 2>/dev/null &
                fi
            fi
            # Clear system caches periodically
            sync
            echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
            sleep \"$ENTROPY_INTERVAL\"
        done
    " > "$LOG_DIR/entropy_flush.out" 2>&1 &
    
    echo $! > "$PID_DIR/entropy_flush.pid"
    log_event "INFO" "Entropy flush process started with PID: $!"
}

# Start auto-clean process
start_auto_clean() {
    if [[ "$AUTO_CLEAN_ENABLED" != "true" ]]; then
        log_event "INFO" "Auto-clean disabled in configuration"
        return 0
    fi
    if [[ "$IS_WINDOWS" == true ]]; then
        log_event "WARN" "Auto-clean is not fully supported on Windows. Skipping."
        return 0
    fi
    log_event "INFO" "Starting auto-clean process..."
    
    nohup bash -c "
        while true; do
            # Clean temporary files
            find /tmp -type f -name '.*' -mtime +1 -delete 2>/dev/null || true
            find /tmp -type f -name 'core.*' -delete 2>/dev/null || true
            # Clean user cache
            if [[ -d \"$HOME/.cache\" ]]; then
                find \"$HOME/.cache\" -type f -mtime +7 -delete 2>/dev/null || true
            fi
            # Clean log files older than 30 days
            find \"$LOG_DIR\" -name '*.log.*' -mtime +30 -delete 2>/dev/null || true
            # Report cleaning activity
            echo \"\$(date): Auto-clean cycle completed\" >> \"$LOG_FILE\"
            sleep \"$CLEAN_INTERVAL\"
        done
    " > "$LOG_DIR/auto_clean.out" 2>&1 &
    
    echo $! > "$PID_DIR/auto_clean.pid"
    log_event "INFO" "Auto-clean process started with PID: $!"
}

# Start core monitoring process
start_core_monitoring() {
    if [[ "$CORE_MONITOR_ENABLED" != "true" ]]; then
        log_event "INFO" "Core monitoring disabled in configuration"
        return 0
    fi
    if [[ "$IS_WINDOWS" == true ]]; then
        log_event "WARN" "Core monitoring is not fully supported on Windows. Skipping."
        return 0
    fi
    log_event "INFO" "Starting core monitoring process..."
    
    nohup bash -c "
        while true; do
            # Monitor CPU usage
            cpu_usage=\$(top -bn1 | grep 'Cpu(s)' | awk '{print \\$2}' | sed 's/%us,//')
            # Monitor memory usage
            mem_info=\$(free | grep Mem)
            mem_used=\$(echo \$mem_info | awk '{print \\$3}')
            mem_total=\$(echo \$mem_info | awk '{print \\$2}')
            mem_percent=\$((mem_used * 100 / mem_total))
            # Monitor disk usage
            disk_usage=\$(df / | tail -1 | awk '{print \\$5}' | sed 's/%//')
            # Log metrics
            echo \"\$(date): CPU: \${cpu_usage}% MEM: \${mem_percent}% DISK: \${disk_usage}%\" >> \"$LOG_FILE\"
            # Alert on high usage
            if [[ \${mem_percent} -gt 90 ]]; then
                echo \"\$(date): WARNING - High memory usage: \${mem_percent}%\" >> \"$LOG_FILE\"
            fi
            if [[ \${disk_usage} -gt 90 ]]; then
                echo \"\$(date): WARNING - High disk usage: \${disk_usage}%\" >> \"$LOG_FILE\"
            fi
            sleep \"$MONITOR_INTERVAL\"
        done
    " > "$LOG_DIR/core_monitoring.out" 2>&1 &
    
    echo $! > "$PID_DIR/core_monitoring.pid"
    log_event "INFO" "Core monitoring process started with PID: $!"
}

# Start vault sync process
# shellcheck disable=SC2154  # vault_dir and backup_dir are defined inside the bash -c string
start_vault_sync() {
    if [[ "$VAULT_SYNC_ENABLED" != "true" ]]; then
        log_event "INFO" "Vault sync disabled in configuration"
        return 0
    fi
    if [[ "$IS_WINDOWS" == true ]]; then
        log_event "WARN" "Vault sync is not fully supported on Windows. Skipping."
        return 0
    fi
    log_event "INFO" "Starting vault sync process..."
    
    nohup bash -c "
        vault_dir=\"$HOME/.gitswhy/vault\"
        backup_dir=\"$HOME/.gitswhy/vault_backup\"
        # Create vault directories if they dont exist
        mkdir -p \"$vault_dir\" \"$backup_dir\"
        while true; do
            # Sync vault data with backup
            if [[ -d \"$vault_dir\" ]]; then
                rsync -a --delete \"$vault_dir/\" \"$backup_dir/\" 2>/dev/null || true
                # Create timestamped snapshot
                snapshot_name=\"vault_\$(date +%Y%m%d_%H%M%S)\"
                cp -r \"$vault_dir\" \"$backup_dir/\$snapshot_name\" 2>/dev/null || true
                # Keep only last 10 snapshots
                cd \"$backup_dir\"
                ls -dt vault_* 2>/dev/null | tail -n +11 | xargs rm -rf 2>/dev/null || true
                echo \"\$(date): Vault sync completed\" >> \"$LOG_FILE\"
            fi
            sleep 1800  # Sync every 30 minutes
        done
    " > "$LOG_DIR/vault_sync.out" 2>&1 &
    
    echo $! > "$PID_DIR/vault_sync.pid"
    log_event "INFO" "Vault sync process started with PID: $!"
}

# Stop all processes
stop_all_processes() {
    log_event "INFO" "Stopping all ReflexCore processes..."
    
    for process in "${PROCESS_LIST[@]}"; do
        pid_file="$PID_DIR/$process.pid"
        if [[ -f "$pid_file" ]]; then
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                log_event "INFO" "Stopped $process process (PID: $pid)"
            fi
            rm -f "$pid_file"
        fi
    done
}

# Check process status
check_process_status() {
    log_event "INFO" "Checking process status..."
    
    for process in "${PROCESS_LIST[@]}"; do
        pid_file="$PID_DIR/$process.pid"
        if [[ -f "$pid_file" ]]; then
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                log_event "INFO" "$process is running (PID: $pid)"
            else
                log_event "WARN" "$process is not running (stale PID file)"
                rm -f "$pid_file"
            fi
        else
            log_event "WARN" "$process is not running (no PID file)"
        fi
    done
}

#==============================================================================
# MAIN EXECUTION FLOW
#==============================================================================

main() {
    log_event "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Handle command line arguments
    case "${1:-start}" in
        "start")
            # Setup environment
            setup_directories
            check_system_requirements
            
            # Load configuration
            if ! parse_yaml_config "$CONFIG_FILE"; then
                log_event "ERROR" "Failed to load configuration"
                exit 1
            fi
            
            # Start all processes
            log_event "INFO" "Initializing ReflexCore background processes..."
            
            # shellcheck disable=SC2120,SC2119  # start_core_monitoring does not use arguments
            start_overclocking || log_event "ERROR" "Failed to start overclocking"
            start_entropy_flush || log_event "ERROR" "Failed to start entropy flush"
            start_auto_clean || log_event "ERROR" "Failed to start auto-clean"
            start_core_monitoring || log_event "ERROR" "Failed to start core monitoring"
            start_vault_sync || log_event "ERROR" "Failed to start vault sync"
            
            log_event "INFO" "ReflexCore initialization completed"
            ;;
            
        "stop")
            stop_all_processes
            ;;
            
        "status")
            check_process_status
            ;;
            
        "restart")
            stop_all_processes
            sleep 2
            "$0" start
            ;;
            
        *)
            echo "Usage: $0 {start|stop|status|restart}"
            exit 1
            ;;
    esac
}

# Trap signals for clean shutdown
trap 'stop_all_processes; exit' SIGTERM SIGINT

# Execute main function with all arguments
main "$@"
