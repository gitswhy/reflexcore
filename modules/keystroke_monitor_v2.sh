#!/bin/bash

#==============================================================================
# Gitswhy OS - Keystroke Monitor v2.0 (FRESH VERSION)
# File: modules/keystroke_monitor_v2.sh
# Description: Monitors keystrokes and detects typing hesitations
# Author: ReflexCore Development Team
# Version: 2.0.0
#==============================================================================

# Script metadata
SCRIPT_NAME="KeystrokeMonitorV2"
SCRIPT_VERSION="2.0.0"
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
CYAN='\033[0;36m'
NC='\033[0m' # No Colo

# Default values
HESITATION_THRESHOLD=2.0
MONITORING_ENABLED=true
ALERT_ENABLED=true
JSON_LOGGING=true

# Terminal state variables
ORIGINAL_STTY_SETTINGS=""
LAST_KEYSTROKE_TIME=""

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Get timestamp
get_timestamp() {
    date +%s.%N
}

# Get ISO timestamp for JSON logging
get_iso_timestamp() {
    date --iso-8601=seconds
}

# Parse YAML configuration
parse_yaml_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Configuration file not found: $config_file - using defaults"
        return 0
    fi
    
    # Extract configuration values
    MONITORING_ENABLED=$(grep -E "^\s*keystroke_monitoring_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    MONITORING_ENABLED=$(echo "$MONITORING_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    HESITATION_THRESHOLD=$(grep -E "^\s*hesitation_threshold:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "2.0")
    ALERT_ENABLED=$(grep -E "^\s*hesitation_alerts_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "true")
    JSON_LOGGING=$(grep -E "^\s*json_logging_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "true")
    
    echo -e "${GREEN}[INFO]${NC} Configuration loaded: Threshold=${HESITATION_THRESHOLD}s, Monitoring=${MONITORING_ENABLED}"
}

# JSON logging function
log_json_event() {
    local event_type="$1"
    local message="$2"
    local interval="${3:-0}"
    local keystroke="${4:-}"
    
    if [[ "$JSON_LOGGING" != "true" ]]; then
        return 0
    fi
    
    mkdir -p "$LOG_DIR"
    
    local timestamp
    timestamp=$(get_iso_timestamp)
    local json_entry="{\"timestamp\": \"$timestamp\", \"script\": \"keystroke_monitor_v2\", \"event_type\": \"$event_type\", \"message\": \"$message\", \"interval\": $interval, \"keystroke\": \"$keystroke\", \"hesitation_threshold\": $HESITATION_THRESHOLD}"
    echo "$json_entry" >> "$LOG_FILE"
}

#==============================================================================
# TERMINAL MANAGEMENT
#==============================================================================

# Setup terminal for raw input
setup_raw_mode() {
    echo -e "${BLUE}[DEBUG]${NC} Setting up raw terminal mode..."
    
    if [[ ! -t 0 ]]; then
        echo -e "${YELLOW}[WARN]${NC} Not running in interactive terminal. Skipping raw mode setup."
        return 0
    fi
    
    if ! command -v stty >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} stty command not available. Skipping raw mode setup."
        return 0
    fi
    
    ORIGINAL_STTY_SETTINGS=$(stty -g 2>/dev/null || echo "")
    
    if [[ -z "$ORIGINAL_STTY_SETTINGS" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Could not save terminal settings. Skipping raw mode setup."
        return 0
    fi
    
    if ! timeout 5s stty -echo -icanon -isig min 1 time 0 2>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} Failed to configure terminal for raw mode. Continuing with default settings."
        return 0
    fi
    
    echo -e "${GREEN}[INFO]${NC} Terminal configured for raw keystroke monitoring"
    log_json_event "setup" "Terminal configured for raw mode" "0"
}

# Restore terminal settings
restore_terminal() {
    if [[ -n "$ORIGINAL_STTY_SETTINGS" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} Restoring original terminal settings..."
        stty "$ORIGINAL_STTY_SETTINGS" 2>/dev/null || true
        echo -e "${GREEN}[INFO]${NC} Terminal settings restored"
        log_json_event "cleanup" "Terminal settings restored" "0"
    fi
}

#==============================================================================
# KEYSTROKE MONITORING
#==============================================================================

# Read single character - FRESH VERSION
read_keystroke() {
    local char
    
    if [[ ! -t 0 ]]; then
        sleep 0.1
        echo "TIMEOUT"
        return
    fi
    
    # Simple read with timeout - no complex logic
    if read -r -t 1 -n 1 char 2>/dev/null; then
        case "$char" in
            $'\x03') # Ctrl+C
                echo "CTRL+C"
                ;;
            *) # All other characters
                echo "$char"
                ;;
        esac
    else
        echo "TIMEOUT"
    fi
}

# Check for hesitation
check_hesitation() {
    local current_time="$1"
    local keystroke="$2"
    
    if [[ -n "$LAST_KEYSTROKE_TIME" ]]; then
        local interval
        interval=$(echo "$current_time - $LAST_KEYSTROKE_TIME" | bc -l 2>/dev/null || echo "0")
        
        if (( $(echo "$interval > $HESITATION_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            local formatted_interval
            formatted_interval=$(printf "%.2f" "$interval")
            
            if [[ "$ALERT_ENABLED" == "true" ]]; then
                echo -e "\n${RED}[GitsWhy] Hesitation detected: ${formatted_interval}s${NC}"
            fi
            
            log_json_event "hesitation" "Hesitation detected" "$formatted_interval" "$keystroke"
            return 0
        else
            log_json_event "keystroke" "Normal keystroke" "$interval" "$keystroke"
        fi
    else
        log_json_event "keystroke" "Initial keystroke" "0" "$keystroke"
    fi
    
    return 1
}

# Main monitoring loop - FRESH VERSION
monitor_keystrokes() {
    local keystroke_count=0
    local hesitation_count=0
    local timeout_count=0
    local max_timeouts=30
    
    echo -e "${CYAN}[MONITOR]${NC} Starting keystroke monitoring..."
    echo -e "${CYAN}[MONITOR]${NC} Hesitation threshold: ${HESITATION_THRESHOLD}s"
    echo -e "${CYAN}[MONITOR]${NC} Press Ctrl+C to stop monitoring"
    echo ""
    
    log_json_event "start" "Keystroke monitoring started" "0"
    
    # Simple infinite loop - no complex conditions
    while true; do
        local current_time
        current_time=$(get_timestamp)
        
        local keystroke
        keystroke=$(read_keystroke 2>/dev/null || echo "TIMEOUT")
        
        # Handle Ctrl+C
        if [[ "$keystroke" == "CTRL+C" ]]; then
            echo -e "\n${YELLOW}[INFO]${NC} Ctrl+C detected, stopping monitoring..."
            break
        fi
        
        # Handle timeout
        if [[ "$keystroke" == "TIMEOUT" ]]; then
            ((timeout_count++))
            
            if (( timeout_count % 10 == 0 )); then
                echo -e "${YELLOW}[INFO]${NC} No keystrokes detected for ${timeout_count}s"
            fi
            
            if (( timeout_count >= max_timeouts )); then
                echo -e "${YELLOW}[INFO]${NC} No keystrokes detected for ${max_timeouts}s"
                echo -e "${YELLOW}[INFO]${NC} Exiting due to inactivity"
                break
            fi
            
            continue
        fi
        
        # Increment counte
        ((keystroke_count++))
        
        if check_hesitation "$current_time" "$keystroke"; then
            ((hesitation_count++))
        fi
        
        LAST_KEYSTROKE_TIME="$current_time"
        
        # Visual feedback
        echo -n -e "${GREEN}.${NC}"
        
        if (( keystroke_count % 50 == 0 )); then
            echo -e "\n${BLUE}[STATUS]${NC} Keystrokes: $keystroke_count, Hesitations: $hesitation_count"
        fi
    done
    
    echo -e "\n${CYAN}[MONITOR]${NC} Monitoring stopped"
    echo -e "${CYAN}[SUMMARY]${NC} Total keystrokes: $keystroke_count"
    echo -e "${CYAN}[SUMMARY]${NC} Hesitations detected: $hesitation_count"
    
    if (( keystroke_count == 0 )); then
        echo -e "${YELLOW}[INFO]${NC} No keystrokes were detected"
        log_json_event "stop" "Monitoring stopped - no keystrokes detected" "0" "non_interactive:true"
    else
        log_json_event "stop" "Monitoring stopped" "0" "total_keystrokes:$keystroke_count,hesitations:$hesitation_count"
    fi
}

#==============================================================================
# MAIN EXECUTION FLOW
#==============================================================================

# Display script information
show_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE} $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${PURPLE} Keystroke Monitoring & Hesitation Detection${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
}

# Check system requirements
check_requirements() {
    local missing_commands=()
    
    if ! command -v bc >/dev/null 2>&1; then
        missing_commands+=("bc")
    fi
    
    if ! command -v timeout >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} timeout command not available. Some features may be limited."
    fi
    
    if ! command -v stty >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} stty command not available. Raw terminal mode will be disabled."
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Missing required commands: ${missing_commands[*]}"
        echo -e "${YELLOW}[INFO]${NC} Install with: sudo apt-get install ${missing_commands[*]}"
        return 1
    fi
    
    echo -e "${GREEN}[INFO]${NC} System requirements satisfied"
    return 0
}

# Main function
main() {
    show_header
    
    if ! check_requirements; then
        return 1
    fi
    
    parse_yaml_config "$CONFIG_FILE"
    
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Keystroke monitoring is disabled in configuration"
        return 0
    fi
    
    if [[ ! -t 0 ]]; then
        echo -e "${YELLOW}[WARN]${NC} Not running in interactive terminal. Keystroke monitoring requires interactive mode."
        echo -e "${BLUE}[INFO]${NC} For Windows users: Run this in WSL terminal directly"
        
        if [[ -n "$WSL_DISTRO_NAME" ]]; then
            echo -e "${BLUE}[INFO]${NC} WSL detected - continuing despite non-interactive terminal"
        else
            log_json_event "error" "Non-interactive terminal detected" "0"
            return 1
        fi
    fi
    
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo -e "${BLUE}[INFO]${NC} Running in WSL environment: $WSL_DISTRO_NAME"
    fi
    
    # Setup and run - NO SIGNAL TRAPS
    setup_raw_mode
    
    monitor_keystrokes
    
    # Only cleanup if we reach here (normal exit)
    restore_terminal
}

# Handle script arguments
case "${1:-monitor}" in
    "monitor"|"start"|"")
        main
        ;;
    "test")
        echo "Running Keystroke Monitor v2 test sequence..."
        main
        ;;
    "status")
        echo "Keystroke Monitor v2 Status:"
        echo "Config file: $([ -f "$CONFIG_FILE" ] && echo "✓ Found" || echo "✗ Missing")"
        echo "Log directory: $([ -d "$LOG_DIR" ] && echo "✓ Exists" || echo "✗ Missing")"
        if [[ -f "$CONFIG_FILE" ]]; then
            parse_yaml_config "$CONFIG_FILE"
            echo "Monitoring enabled: $MONITORING_ENABLED"
            echo "Hesitation threshold: ${HESITATION_THRESHOLD}s"
            echo "Alert enabled: $ALERT_ENABLED"
        fi
        ;;
    "logs")
        if [[ -f "$LOG_FILE" ]]; then
            echo "Recent keystroke monitoring events:"
            tail -20 "$LOG_FILE" | grep '"script": "keystroke_monitor_v2"' || echo "No recent events found"
        else
            echo "No log file found at $LOG_FILE"
        fi
        ;;
    *)
        echo "Usage: $0 {monitor|test|status|logs}"
        echo "  monitor - Start keystroke monitoring (default)"
        echo "  test    - Run test monitoring sequence"
        echo "  status  - Show configuration status"
        echo "  logs    - Show recent monitoring events"
        return 1
        ;;
esac 