#!/bin/bash

#==============================================================================
# Gitswhy OS - Core Mirror Keystroke Monitoring Script
# File: modules/gitswhy_coremirror.sh
# Description: Monitors keystrokes in raw mode and detects typing hesitations
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhyCoreMirror"
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values if config is missing
DEFAULT_HESITATION_THRESHOLD=2.0
DEFAULT_MONITORING_ENABLED=true
DEFAULT_ALERT_ENABLED=true
DEFAULT_JSON_LOGGING=true

# Terminal state variables
ORIGINAL_STTY_SETTINGS=""
MONITORING_ACTIVE=false
LAST_KEYSTROKE_TIME=""

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Get high precision timestamp
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
        HESITATION_THRESHOLD=$DEFAULT_HESITATION_THRESHOLD
        MONITORING_ENABLED=$DEFAULT_MONITORING_ENABLED
        ALERT_ENABLED=$DEFAULT_ALERT_ENABLED
        JSON_LOGGING=$DEFAULT_JSON_LOGGING
        return 0
    fi
    
    # Always check top-level *_enabled flags first
    MONITORING_ENABLED=$(grep -E "^\s*keystroke_monitoring_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    MONITORING_ENABLED=$(echo "$MONITORING_ENABLED" | tr -d '"' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    # Debug output for config flag
    echo "[DEBUG] keystroke_monitoring_enabled=$MONITORING_ENABLED" >&2
    
    # Extract configuration values with error handling
    HESITATION_THRESHOLD=$(grep -E "^\s*hesitation_threshold:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_HESITATION_THRESHOLD")
    ALERT_ENABLED=$(grep -E "^\s*hesitation_alerts_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_ALERT_ENABLED")
    JSON_LOGGING=$(grep -E "^\s*json_logging_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ' || echo "$DEFAULT_JSON_LOGGING")
    
    # Set defaults if extraction failed or values are empty
    HESITATION_THRESHOLD=${HESITATION_THRESHOLD:-$DEFAULT_HESITATION_THRESHOLD}
    ALERT_ENABLED=${ALERT_ENABLED:-$DEFAULT_ALERT_ENABLED}
    JSON_LOGGING=${JSON_LOGGING:-$DEFAULT_JSON_LOGGING}
    
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
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Create JSON log entry
    local timestamp
    timestamp=$(get_iso_timestamp)
    local json_entry="{\"timestamp\": \"$timestamp\", \"script\": \"coremirror\", \"event_type\": \"$event_type\", \"message\": \"$message\", \"interval\": $interval, \"keystroke\": \"$keystroke\", \"hesitation_threshold\": $HESITATION_THRESHOLD}"
    echo "$json_entry" >> "$LOG_FILE"
}

#==============================================================================
# TERMINAL MANAGEMENT
#==============================================================================

# Save current terminal settings and switch to raw mode
setup_raw_mode() {
    echo -e "${BLUE}[DEBUG]${NC} Setting up raw terminal mode..."
    
    # Check if we're in an interactive terminal
    if [[ ! -t 0 ]]; then
        echo -e "${YELLOW}[WARN]${NC} Not running in interactive terminal. Skipping raw mode setup."
        return 0
    fi
    
    # Check if stty is available
    if ! command -v stty >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} stty command not available. Skipping raw mode setup."
        return 0
    fi
    
    # Save original terminal settings for restoration
    ORIGINAL_STTY_SETTINGS=$(stty -g 2>/dev/null || echo "")
    
    if [[ -z "$ORIGINAL_STTY_SETTINGS" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Could not save terminal settings. Skipping raw mode setup."
        return 0
    fi
    
    # Configure terminal for raw input with timeout
    if ! timeout 5s stty -echo -icanon -isig min 1 time 0 2>/dev/null; then
        echo -e "${YELLOW}[WARN]${NC} Failed to configure terminal for raw mode. Continuing with default settings."
        return 0
    fi
    
    echo -e "${GREEN}[INFO]${NC} Terminal configured for raw keystroke monitoring"
    log_json_event "setup" "Terminal configured for raw mode" "0"
}

# Restore original terminal settings
restore_terminal() {
    if [[ -n "$ORIGINAL_STTY_SETTINGS" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} Restoring original terminal settings..."
        stty "$ORIGINAL_STTY_SETTINGS"
        echo -e "${GREEN}[INFO]${NC} Terminal settings restored"
        log_json_event "cleanup" "Terminal settings restored" "0"
    fi
}

#==============================================================================
# SIGNAL HANDLING AND CLEANUP
#==============================================================================

# Cleanup function called on script exit
cleanup() {
    echo -e "\n${YELLOW}[INFO]${NC} Cleaning up and exiting..."
    
    # Stop monitoring
    MONITORING_ACTIVE=false
    
    # Restore terminal state
    restore_terminal
    
    # Log final statistics if available
    log_json_event "exit" "Keystroke monitoring stopped" "0"
    
    echo -e "${GREEN}[INFO]${NC} Cleanup completed"
    exit 0
}

# Set up signal traps for clean exit
setup_signal_traps() {
    # Trap SIGINT (Ctrl+C) for clean cleanup
    trap 'cleanup' SIGINT
    
    # Trap EXIT to ensure cleanup runs
    trap 'restore_terminal' EXIT
    
    echo -e "${BLUE}[DEBUG]${NC} Signal traps configured"
}

#==============================================================================
# KEYSTROKE MONITORING
#==============================================================================

# Read single character in raw mode
read_keystroke() {
    local char
    
    # Check if we're in an interactive terminal
    if [[ ! -t 0 ]]; then
        echo "TIMEOUT"
        return
    fi
    
    # Try to read with timeout first
    if command -v timeout >/dev/null 2>&1; then
        char=$(timeout 1s dd bs=1 count=1 2>/dev/null || echo "")
    else
        # Fallback: try dd without timeout
        char=$(dd bs=1 count=1 2>/dev/null || echo "")
    fi
    
    # If dd failed or timed out, try alternative method
    if [[ -z "$char" ]]; then
        # Try using read with timeout
        if read -r -t 1 -n 1 char 2>/dev/null; then
            # read succeeded
            :
        else
            # All methods failed
            echo "TIMEOUT"
            return
        fi
    fi
    
    # Handle special characters
    case "$char" in
        $'\x03') # Ctrl+C
            echo "CTRL+C"
            ;;
        $'\x1b') # Escape sequences
            echo "ESC"
            ;;
        $'\n'|$'\r') # Enter/Return
            echo "ENTER"
            ;;
        $'\t') # Tab
            echo "TAB"
            ;;
        ' ') # Space
            echo "SPACE"
            ;;
        '') # Handle empty input
            echo "UNKNOWN"
            ;;
        *) # Regular characters
            # Check if printable character
            if [[ "$char" =~ [[:print:]] ]]; then
                echo "$char"
            else
                # Handle non-printable characters
                printf "\\x%02x" "'$char"
            fi
            ;;
    esac
}

# Calculate typing interval and detect hesitations
check_hesitation() {
    local current_time="$1"
    local keystroke="$2"
    
    if [[ -n "$LAST_KEYSTROKE_TIME" ]]; then
        # Calculate interval using high-precision arithmetic
        local interval
        interval=$(echo "$current_time - $LAST_KEYSTROKE_TIME" | bc -l 2>/dev/null || echo "0")
        
        # Check if interval exceeds threshold
        if (( $(echo "$interval > $HESITATION_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            # Format interval to 2 decimal places
            local formatted_interval
            formatted_interval=$(printf "%.2f" "$interval")
            
            # Print hesitation alert
            if [[ "$ALERT_ENABLED" == "true" ]]; then
                echo -e "\n${RED}[GitsWhy] Hesitation detected: ${formatted_interval}s${NC}"
            fi
            
            # Log hesitation event
            log_json_event "hesitation" "Hesitation detected" "$formatted_interval" "$keystroke"
            
            return 0
        else
            # Log normal keystroke
            log_json_event "keystroke" "Normal keystroke" "$interval" "$keystroke"
        fi
    else
        # First keystroke
        log_json_event "keystroke" "Initial keystroke" "0" "$keystroke"
    fi
    
    return 1
}

# Main keystroke monitoring loop
monitor_keystrokes() {
    local keystroke_count=0
    local hesitation_count=0
    
    echo -e "${CYAN}[MONITOR]${NC} Starting keystroke monitoring..."
    echo -e "${CYAN}[MONITOR]${NC} Hesitation threshold: ${HESITATION_THRESHOLD}s"
    echo -e "${CYAN}[MONITOR]${NC} Press Ctrl+C to stop monitoring"
    echo ""
    
    log_json_event "start" "Keystroke monitoring started" "0"
    
    MONITORING_ACTIVE=true
    
    while [[ "$MONITORING_ACTIVE" == true ]]; do
        # Get current timestamp
        local current_time
        current_time=$(get_timestamp)
        
        # Read single keystroke
        local keystroke
        keystroke=$(read_keystroke)
        
        # Handle Ctrl+C
        if [[ "$keystroke" == "CTRL+C" ]]; then
            break
        fi
        
        # Handle timeout (no input)
        if [[ "$keystroke" == "TIMEOUT" ]]; then
            continue
        fi
        
        # Increment counter
        ((keystroke_count++))
        
        # Check for hesitation and update counters
        if check_hesitation "$current_time" "$keystroke"; then
            ((hesitation_count++))
        fi
        
        # Update last keystroke time
        LAST_KEYSTROKE_TIME="$current_time"
        
        # Display keystroke (optional visual feedback)
        echo -n -e "${GREEN}.${NC}"
        
        # Periodic status update every 50 keystrokes
        if (( keystroke_count % 50 == 0 )); then
            echo -e "\n${BLUE}[STATUS]${NC} Keystrokes: $keystroke_count, Hesitations: $hesitation_count"
        fi
    done
    
    echo -e "\n${CYAN}[MONITOR]${NC} Monitoring stopped"
    echo -e "${CYAN}[SUMMARY]${NC} Total keystrokes: $keystroke_count"
    echo -e "${CYAN}[SUMMARY]${NC} Hesitations detected: $hesitation_count"
    
    log_json_event "stop" "Monitoring stopped" "0" "total_keystrokes:$keystroke_count,hesitations:$hesitation_count"
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
    
    # Check for required commands
    if ! command -v bc >/dev/null 2>&1; then
        missing_commands+=("bc")
    fi
    
    if ! command -v dd >/dev/null 2>&1; then
        missing_commands+=("dd")
    fi
    
    # Check for optional but recommended commands
    if ! command -v timeout >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} timeout command not available. Some features may be limited."
    fi
    
    if ! command -v stty >/dev/null 2>&1; then
        echo -e "${YELLOW}[WARN]${NC} stty command not available. Raw terminal mode will be disabled."
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Missing required commands: ${missing_commands[*]}"
        echo -e "${YELLOW}[INFO]${NC} Install with: sudo apt-get install ${missing_commands[*]}"
        exit 1
    fi
    
    echo -e "${GREEN}[INFO]${NC} System requirements satisfied"
}

# Main function
main() {
    show_header
    
    # Check system requirements
    check_requirements
    
    # Parse configuration
    parse_yaml_config "$CONFIG_FILE"
    
    # Check if monitoring is enabled
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        echo -e "${YELLOW}[WARN]${NC} Keystroke monitoring is disabled in configuration"
        exit 0
    fi
    
    # Check if we're in an interactive terminal
    if [[ ! -t 0 ]]; then
        echo -e "${YELLOW}[WARN]${NC} Not running in interactive terminal. Keystroke monitoring requires interactive mode."
        echo -e "${YELLOW}[WARN]${NC} Please run this script in a terminal window, not in a script or non-interactive environment."
        log_json_event "error" "Non-interactive terminal detected" "0"
        exit 1
    fi
    
    # Set up signal handling for clean exit
    setup_signal_traps
    
    # Configure terminal for raw input
    setup_raw_mode
    
    # Start monitoring keystrokes
    monitor_keystrokes
    
    # Cleanup will be called by trap
}

# Handle script arguments
case "${1:-monitor}" in
    "monitor"|"start"|"")
        main
        ;;
    "test")
        echo "Running Core Mirror test sequence..."
        main
        ;;
    "status")
        echo "Core Mirror Status:"
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
            tail -20 "$LOG_FILE" | grep '"script": "coremirror"' || echo "No recent events found"
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
        exit 1
        ;;
esac 