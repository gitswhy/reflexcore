#!/bin/bash

#==============================================================================
# Gitswhy OS - Vault Sync Script
# File: scripts/gitswhy_vaultsync.sh
# Description: Aggregates events from logs and synchronizes with encrypted vault
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhyVaultSync"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration paths
CONFIG_FILE="$ROOT_DIR/config/gitswhy_config.yaml"
LOG_DIR="$HOME/.gitswhy"
LOG_FILE="$LOG_DIR/events.log"
mkdir -p "$(dirname "$LOG_FILE")"
VAULT_MANAGER="$ROOT_DIR/gitswhy_vault_manager.py"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values if config is missing
DEFAULT_VAULT_SYNC_ENABLED=true
DEFAULT_SYNC_INTERVAL=300
DEFAULT_MAX_EVENTS=1000
DEFAULT_COMPRESSION_ENABLED=true

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Log function with timestamps
log_action() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] [VAULT] [$level] $message" >> "$LOG_FILE"
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "VAULT") echo -e "${PURPLE}[VAULT]${NC} $message" ;;
        *)       echo "[UNKNOWN] $message" ;;
    esac
}

# Check if required commands exist
check_requirements() {
    local missing_commands=()
    if ! command -v python3 >/dev/null 2>&1; then
        missing_commands+=("python3")
    fi
    if [[ ! -f "$VAULT_MANAGER" ]]; then
        log_action "ERROR" "Vault manager script not found: $VAULT_MANAGER"
        exit 1
    fi
    if ! python3 -c "import cryptography" 2>/dev/null; then
        log_action "WARN" "Python cryptography library not installed"
        echo -e "${YELLOW}[INFO]${NC} Install with: pip3 install cryptography"
        missing_commands+=("cryptography")
    fi
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_action "ERROR" "Missing requirements: ${missing_commands[*]}"
        exit 1
    fi
    log_action "INFO" "All requirements satisfied"
}

# Parse YAML configuration
parse_yaml_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        log_action "WARN" "Configuration file not found: $config_file - using defaults"
        VAULT_SYNC_ENABLED=$DEFAULT_VAULT_SYNC_ENABLED
        SYNC_INTERVAL=$DEFAULT_SYNC_INTERVAL
        MAX_EVENTS=$DEFAULT_MAX_EVENTS
        COMPRESSION_ENABLED=$DEFAULT_COMPRESSION_ENABLED
        return 0
    fi
    VAULT_SYNC_ENABLED=$(grep -E "^\s*vault_sync_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || echo "$DEFAULT_VAULT_SYNC_ENABLED")
    SYNC_INTERVAL=$(grep -E "^\s*vault_sync_interval:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_SYNC_INTERVAL")
    MAX_EVENTS=$(grep -E "^\s*vault_max_events:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_MAX_EVENTS")
    COMPRESSION_ENABLED=$(grep -E "^\s*vault_compression_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || echo "$DEFAULT_COMPRESSION_ENABLED")
    VAULT_SYNC_ENABLED=${VAULT_SYNC_ENABLED:-$DEFAULT_VAULT_SYNC_ENABLED}
    SYNC_INTERVAL=${SYNC_INTERVAL:-$DEFAULT_SYNC_INTERVAL}
    MAX_EVENTS=${MAX_EVENTS:-$DEFAULT_MAX_EVENTS}
    COMPRESSION_ENABLED=${COMPRESSION_ENABLED:-$DEFAULT_COMPRESSION_ENABLED}
    log_action "INFO" "Configuration loaded: Sync=$VAULT_SYNC_ENABLED, Interval=${SYNC_INTERVAL}s, MaxEvents=$MAX_EVENTS"
}

# Aggregate events from the log file
aggregate_events() {
    local events_file="$1"
    local max_events="$2"
    log_action "VAULT" "Aggregating events from $LOG_FILE..."
    if [[ ! -f "$LOG_FILE" ]]; then
        log_action "WARN" "Events log file not found: $LOG_FILE"
        echo "[]" > "$events_file"
        return 0
    fi
    echo "[" > "$events_file"
    tail -n "$max_events" "$LOG_FILE" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        # If line is JSON, just append
        if echo "$line" | grep -q '^{.*}$'; then
            echo "  $line," >> "$events_file"
        else
            # Convert plain text log to JSON
            local timestamp
            timestamp=$(echo "$line" | grep -o '\[.*\]' | head -1 | tr -d '[]')
            local level
            level=$(echo "$line" | grep -o '\[.*\]' | sed -n '2p' | tr -d '[]')
            local message
            message=$(echo "$line" | sed 's/\[.*\]\[.*\]\[.*\]//' | sed 's/^[[:space:]]*//')
            message=$(echo "$message" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
            echo "  {\"timestamp\": \"$timestamp\", \"level\": \"$level\", \"message\": \"$message\"}," >> "$events_file"
        fi
    done
    sed -i '$ s/,$//' "$events_file"
    echo "]" >> "$events_file"
    local event_count
    event_count=$(grep -c '"timestamp"' "$events_file" 2>/dev/null || echo "0")
    log_action "INFO" "Aggregated $event_count events"
}

# Get vault statistics
get_vault_stats() {
    if [[ -f "$LOG_DIR/vault.json" ]]; then
        local vault_size
        vault_size=$(du -h "$LOG_DIR/vault.json" 2>/dev/null | cut -f1 || echo "0")
        local vault_modified
        vault_modified=$(stat -c %Y "$LOG_DIR/vault.json" 2>/dev/null || echo "0")
        local vault_age
        vault_age=$(($(date +%s) - vault_modified))
        log_action "DEBUG" "Vault size: $vault_size, Age: ${vault_age}s"
        echo "vault_size:$vault_size,vault_age:${vault_age}s"
    else
        echo "vault_size:0,vault_age:new"
    fi
}

# Sync events to encrypted vault using Python script
sync_to_vault() {
    local events_file="$1"
    local operation="${2:-store}"
    log_action "VAULT" "Synchronizing events to vault..."
    if python3 "$VAULT_MANAGER" \
        --config "$CONFIG_FILE" \
        --operation "$operation" \
        --input-file "$events_file" \
        --vault-file "$LOG_DIR/vault.json" 2>&1; then
        log_action "INFO" "✓ Events successfully synchronized to vault"
        rm -f "$events_file"
        return 0
    else
        local exit_code=$?
        log_action "ERROR" "Failed to sync events to vault (exit code: $exit_code)"
        return $exit_code
    fi
}

# Retrieve and decrypt vault contents
retrieve_from_vault() {
    local output_format="${1:-json}"
    log_action "VAULT" "Retrieving data from vault..."
    if python3 "$VAULT_MANAGER" \
        --config "$CONFIG_FILE" \
        --operation "retrieve" \
        --vault-file "$LOG_DIR/vault.json" \
        --output-format "$output_format" 2>&1; then
        log_action "INFO" "✓ Vault data retrieved successfully"
        return 0
    else
        local exit_code=$?
        log_action "ERROR" "Failed to retrieve vault data (exit code: $exit_code)"
        return $exit_code
    fi
}

# Create backup of vault
backup_vault() {
    if [[ -f "$LOG_DIR/vault.json" ]]; then
        local backup_file="$LOG_DIR/vault_backup_$(date +%Y%m%d_%H%M%S).json"
        if cp "$LOG_DIR/vault.json" "$backup_file"; then
            log_action "INFO" "Vault backed up to: $backup_file"
            find "$LOG_DIR" -name "vault_backup_*.json" -type f | sort | head -n -5 | xargs rm -f 2>/dev/null || true
        else
            log_action "WARN" "Failed to create vault backup"
        fi
    fi
}

# Display vault status
show_vault_status() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${CYAN} Vault Synchronization Status${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    if [[ -f "$LOG_DIR/vault.json" ]]; then
        echo -e "${GREEN}[INFO]${NC} Vault exists: $LOG_DIR/vault.json"
        local stats
        stats=$(get_vault_stats)
        echo -e "${GREEN}[INFO]${NC} Vault statistics: $stats"
    else
        echo -e "${YELLOW}[WARN]${NC} No vault found - will be created on first sync"
    fi
    if [[ -f "$LOG_FILE" ]]; then
        local log_lines
        log_lines=$(wc -l "$LOG_FILE" || echo "0")
        echo -e "${GREEN}[INFO]${NC} Events log: $log_lines lines"
    else
        echo -e "${YELLOW}[WARN]${NC} No events log found"
    fi
    echo ""
}

# Main function
main() {
    local operation="${1:-sync}"
    check_requirements
    parse_yaml_config "$CONFIG_FILE"
    if [[ "$VAULT_SYNC_ENABLED" != "true" && "$operation" == "sync" ]]; then
        log_action "WARN" "Vault synchronization is disabled in configuration"
        exit 0
    fi
    case "$operation" in
        "sync")
            show_vault_status
            backup_vault
            local temp_events
            temp_events=$(mktemp)
            trap "rm -f $temp_events" EXIT
            aggregate_events "$temp_events" "$MAX_EVENTS"
            sync_to_vault "$temp_events" "store"
            log_action "VAULT" "Vault synchronization completed"
            ;;
        "retrieve"|"view")
            retrieve_from_vault "${2:-json}"
            ;;
        "status")
            show_vault_status
            ;;
        "backup")
            backup_vault
            ;;
        *)
            echo "Usage: $0 {sync|retrieve|view|status|backup}"
            echo "  sync     - Aggregate events and sync to vault (default)"
            echo "  retrieve - Decrypt and retrieve vault contents"
            echo "  view     - View decrypted vault contents"
            echo "  status   - Show vault status"
            echo "  backup   - Create vault backup"
            exit 1
            ;;
    esac
}

main "$@" 