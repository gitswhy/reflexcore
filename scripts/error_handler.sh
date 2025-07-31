#!/bin/bash

# ReflexCore Error Handling System
# Provides robust error handling, logging, and recovery mechanisms

set -euo pipefail

# Error handling configuration
ERROR_LOG_FILE="${ERROR_LOG_FILE:-$HOME/.gitswhy/errors.log}"
MAX_RETRIES=3
RETRY_DELAY=2
COMMAND_TIMEOUT=30

# Error tracking
ERROR_COUNT=0
WARNING_COUNT=0
LAST_ERROR=""
LAST_ERROR_CODE=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Enhanced error logging
log_error() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$ERROR_LOG_FILE")"
    
    # Log to file
    echo "[$timestamp] [$level] [ctx:$context] $message" >> "$ERROR_LOG_FILE"
    
    # Console output
    case "$level" in
        "FATAL") echo -e "${RED}[FATAL]${NC} $message" >&2 ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
    esac
    
    # Update counters
    case "$level" in
        "FATAL"|"ERROR") ((ERROR_COUNT++)) ;;
        "WARN") ((WARNING_COUNT++)) ;;
    esac
}

# Safe command execution with timeout and retry
safe_execute() {
    local command="$1"
    local timeout="${2:-$COMMAND_TIMEOUT}"
    local max_retries="${3:-$MAX_RETRIES}"
    local context="${4:-}"
    
    local attempt=1
    local last_error_code=0
    
    while [[ $attempt -le $max_retries ]]; do
        log_error "DEBUG" "Executing: $command (attempt $attempt/$max_retries)" "$context"
        
        if timeout "$timeout" bash -c "$command" 2>/tmp/error_$$; then
            log_error "DEBUG" "Command succeeded" "$context"
            rm -f /tmp/error_$$
            return 0
        else
            last_error_code=$?
            local error_output
            error_output=$(cat /tmp/error_$$ 2>/dev/null || echo "Unknown error")
            rm -f /tmp/error_$$
            
            log_error "WARN" "Command failed (exit: $last_error_code): $command" "$context"
            log_error "DEBUG" "Error: $error_output" "$context"
            
            LAST_ERROR="$error_output"
            LAST_ERROR_CODE=$last_error_code
            
            if [[ $attempt -lt $max_retries ]]; then
                local delay
                delay=$((RETRY_DELAY * attempt))
                log_error "INFO" "Retrying in ${delay}s..." "$context"
                sleep "$delay"
                ((attempt++))
            else
                log_error "ERROR" "Command failed after $max_retries attempts" "$context"
                return $last_error_code
            fi
        fi
    done
}

# Validate required commands
validate_commands() {
    local commands=("$@")
    local missing=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "ERROR" "Missing commands: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Check system resources
check_resources() {
    local issues=()
    
    # Check disk space
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    if [[ $disk_usage -gt 90 ]]; then
        issues+=("High disk usage: ${disk_usage}%")
    fi
    
    # Check memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}' 2>/dev/null || echo "0")
    if [[ $mem_usage -gt 90 ]]; then
        issues+=("High memory usage: ${mem_usage}%")
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        log_error "WARN" "Resource issues detected:"
        for issue in "${issues[@]}"; do
            log_error "WARN" "  - $issue"
        done
        return 1
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    log_error "INFO" "Performing cleanup..."
    
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Clean temporary files
    rm -f /tmp/error_$$ 2>/dev/null || true
    
    # Reset terminal
    if [[ -t 1 ]] && command -v stty >/dev/null 2>&1; then
        stty sane 2>/dev/null || true
    fi
    
    log_error "INFO" "Cleanup completed"
}

# Set up error handling
setup_error_handling() {
    # Create log directory
    mkdir -p "$(dirname "$ERROR_LOG_FILE")"
    
    # Set up signal handlers
    trap 'cleanup; exit 1' SIGINT SIGTERM
    trap 'cleanup' EXIT
    
    log_error "INFO" "Error handling system initialized"
}

# Export functions
export -f log_error safe_execute validate_commands check_resources cleanup setup_error_handling 