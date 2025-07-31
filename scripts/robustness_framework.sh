#!/bin/bash

#==============================================================================
# ReflexCore Robustness Framework
# File: scripts/robustness_framework.sh
# Description: Comprehensive error handling, validation, and recovery framework
# Author: ReflexCore Development Team
# Version: 2.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# ROBUSTNESS CONFIGURATION
#==============================================================================

# Framework metadata
FRAMEWORK_VERSION="2.0.0"
FRAMEWORK_NAME="ReflexCoreRobustness"

# Error handling levels
ERROR_LEVEL_FATAL=1
ERROR_LEVEL_ERROR=2
ERROR_LEVEL_WARN=3
ERROR_LEVEL_INFO=4
ERROR_LEVEL_DEBUG=5

# Recovery strategies
RECOVERY_RETRY=1
RECOVERY_FALLBACK=2
RECOVERY_SKIP=3
RECOVERY_EXIT=4

# Timeout configurations
DEFAULT_TIMEOUT=30
COMMAND_TIMEOUT=10
NETWORK_TIMEOUT=15
FILE_OPERATION_TIMEOUT=5

# Retry configurations
MAX_RETRIES=3
RETRY_DELAY=2
BACKOFF_MULTIPLIER=2

#==============================================================================
# GLOBAL VARIABLES
#==============================================================================

# Error tracking
ERROR_COUNT=0
WARNING_COUNT=0
RECOVERY_ATTEMPTS=0
LAST_ERROR=""
LAST_ERROR_CODE=0

# Performance tracking
SCRIPT_START_TIME=$(date +%s)
OPERATION_TIMEOUTS=0
COMMAND_FAILURES=0

# System state
SYSTEM_HEALTH_STATUS="unknown"
CRITICAL_RESOURCES=()
DEPENDENCY_STATUS=()

#==============================================================================
# CORE ROBUSTNESS FUNCTIONS
#==============================================================================

# Enhanced logging with error levels and context
robust_log() {
    local level="${1:-INFO}"
    local message="${2:-No message provided}"
    local context="${3:-}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    
    # Determine log level
    local level_num
    case "$level" in
        "FATAL") level_num=$ERROR_LEVEL_FATAL ;;
        "ERROR") level_num=$ERROR_LEVEL_ERROR ;;
        "WARN")  level_num=$ERROR_LEVEL_WARN ;;
        "INFO")  level_num=$ERROR_LEVEL_INFO ;;
        "DEBUG") level_num=$ERROR_LEVEL_DEBUG ;;
        *)       level_num=$ERROR_LEVEL_INFO ;;
    esac
    
    # Color codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local NC='\033[0m'
    
    # Format context
    local context_str=""
    if [[ -n "$context" ]]; then
        context_str=" [ctx:$context]"
    fi
    
    # Log to file
    local log_entry="[$timestamp] [ROBUST] [$level]${context_str} $message"
    echo "$log_entry" >> "${LOG_FILE:-/tmp/reflexcore_robust.log}"
    
    # Console output with colors
    case "$level" in
        "FATAL") echo -e "${RED}[FATAL]${NC} $message" >&2 ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        *)       echo "[$level] $message" ;;
    esac
    
    # Update error counters
    case "$level" in
        "FATAL"|"ERROR") ((ERROR_COUNT++)) ;;
        "WARN") ((WARNING_COUNT++)) ;;
    esac
}

# Robust command execution with timeout and retry
robust_execute() {
    local command="$1"
    local timeout="${2:-$COMMAND_TIMEOUT}"
    local max_retries="${3:-$MAX_RETRIES}"
    local context="${4:-}"
    local recovery_strategy="${5:-$RECOVERY_RETRY}"
    
    local attempt=1
    local last_error_code=0
    
    while [[ $attempt -le $max_retries ]]; do
        robust_log "DEBUG" "Executing command (attempt $attempt/$max_retries): $command" "$context"
        
        # Execute with timeout
        if timeout "$timeout" bash -c "$command" 2>/tmp/robust_error_$$; then
            robust_log "DEBUG" "Command succeeded on attempt $attempt" "$context"
            rm -f /tmp/robust_error_$$
            return 0
        else
            last_error_code=$?
            local error_output
            error_output=$(cat /tmp/robust_error_$$ 2>/dev/null || echo "Unknown error")
            rm -f /tmp/robust_error_$$
            
            robust_log "WARN" "Command failed (attempt $attempt/$max_retries, exit: $last_error_code): $command" "$context"
            robust_log "DEBUG" "Error output: $error_output" "$context"
            
            # Update failure tracking
            ((COMMAND_FAILURES++))
            LAST_ERROR="$error_output"
            LAST_ERROR_CODE=$last_error_code
            
            # Handle recovery strategy
            case $recovery_strategy in
                $RECOVERY_RETRY)
                    if [[ $attempt -lt $max_retries ]]; then
                        local delay
                        delay=$((RETRY_DELAY * (BACKOFF_MULTIPLIER ** (attempt - 1))))
                        robust_log "INFO" "Retrying in ${delay}s..." "$context"
                        sleep "$delay"
                        ((attempt++))
                        continue
                    fi
                    ;;
                $RECOVERY_FALLBACK)
                    robust_log "INFO" "Attempting fallback strategy..." "$context"
                    return $last_error_code
                    ;;
                $RECOVERY_SKIP)
                    robust_log "WARN" "Skipping failed command" "$context"
                    return 0
                    ;;
                $RECOVERY_EXIT)
                    robust_log "FATAL" "Critical command failed, exiting" "$context"
                    exit $last_error_code
                    ;;
            esac
            
            # If we get here, all retries failed
            robust_log "ERROR" "Command failed after $max_retries attempts: $command" "$context"
            return $last_error_code
        fi
    done
}

# System health check
check_system_health() {
    local health_score=100
    local issues=()
    
    robust_log "INFO" "Performing system health check..."
    
    # Check disk space
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    if [[ $disk_usage -gt 90 ]]; then
        issues+=("High disk usage: ${disk_usage}%")
        ((health_score -= 20))
    fi
    
    # Check memory usage
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}' 2>/dev/null || echo "0")
    if [[ $mem_usage -gt 90 ]]; then
        issues+=("High memory usage: ${mem_usage}%")
        ((health_score -= 15))
    fi
    
    # Check load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "0")
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo "1")
    local load_per_core
    load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc 2>/dev/null || echo "0")
    
    if (( $(echo "$load_per_core > 2.0" | bc -l 2>/dev/null || echo "0") )); then
        issues+=("High system load: ${load_per_core} per core")
        ((health_score -= 10))
    fi
    
    # Check critical processes
    local critical_processes=("systemd" "sshd" "cron")
    for proc in "${critical_processes[@]}"; do
        if ! pgrep -x "$proc" >/dev/null 2>&1; then
            issues+=("Critical process missing: $proc")
            ((health_score -= 25))
        fi
    done
    
    # Determine health status
    if [[ $health_score -ge 80 ]]; then
        SYSTEM_HEALTH_STATUS="healthy"
    elif [[ $health_score -ge 60 ]]; then
        SYSTEM_HEALTH_STATUS="degraded"
    else
        SYSTEM_HEALTH_STATUS="critical"
    fi
    
    robust_log "INFO" "System health: $SYSTEM_HEALTH_STATUS (score: $health_score/100)"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        robust_log "WARN" "Health issues detected:"
        for issue in "${issues[@]}"; do
            robust_log "WARN" "  - $issue"
        done
    fi
    
    return $((health_score < 60 ? 1 : 0))
}

# Dependency validation
validate_dependencies() {
    local missing_deps=()
    local optional_deps=()
    
    robust_log "INFO" "Validating system dependencies..."
    
    # Required dependencies
    local required_commands=("bash" "grep" "awk" "sed" "cat" "echo" "date")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Optional but recommended dependencies
    local optional_commands=("bc" "timeout" "stty" "dd" "rsync" "cpufreq-set")
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            optional_deps+=("$cmd")
        fi
    done
    
    # Check Python dependencies
    if command -v python3 >/dev/null 2>&1; then
        local python_packages=("click" "cryptography" "pyyaml")
        for pkg in "${python_packages[@]}"; do
            if ! python3 -c "import $pkg" 2>/dev/null; then
                optional_deps+=("python3-$pkg")
            fi
        done
    else
        optional_deps+=("python3")
    fi
    
    # Report results
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        robust_log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        robust_log "ERROR" "Install with: sudo apt install ${missing_deps[*]}"
        return 1
    fi
    
    if [[ ${#optional_deps[@]} -gt 0 ]]; then
        robust_log "WARN" "Missing optional dependencies: ${optional_deps[*]}"
        robust_log "INFO" "Some features may be limited"
    fi
    
    robust_log "INFO" "Dependency validation completed"
    return 0
}

# Resource monitoring
monitor_resources() {
    local resource="$1"
    local threshold="${2:-80}"
    local current_usage
    
    case "$resource" in
        "disk")
            current_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
            ;;
        "memory")
            current_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}' 2>/dev/null || echo "0")
            ;;
        "cpu")
            current_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//' 2>/dev/null || echo "0")
            ;;
        *)
            robust_log "ERROR" "Unknown resource: $resource"
            return 1
            ;;
    esac
    
    if [[ $current_usage -gt $threshold ]]; then
        robust_log "WARN" "High $resource usage: ${current_usage}% (threshold: ${threshold}%)"
        return 1
    fi
    
    return 0
}

# Graceful error recovery
recover_from_error() {
    local error_code="$1"
    local context="${2:-}"
    local recovery_attempts="${3:-1}"
    
    robust_log "INFO" "Attempting error recovery (code: $error_code, context: $context)" "$context"
    
    case $error_code in
        1)  # General error
            robust_log "INFO" "Performing general error recovery..." "$context"
            ;;
        2)  # Permission denied
            robust_log "INFO" "Attempting permission recovery..." "$context"
            ;;
        124) # Timeout
            robust_log "INFO" "Handling timeout error..." "$context"
            ;;
        127) # Command not found
            robust_log "INFO" "Handling missing command error..." "$context"
            ;;
        *)
            robust_log "WARN" "Unknown error code: $error_code" "$context"
            ;;
    esac
    
    # Increment recovery attempts
    ((RECOVERY_ATTEMPTS++))
    
    # Log recovery attempt
    robust_log "DEBUG" "Recovery attempt $RECOVERY_ATTEMPTS completed" "$context"
}

# Performance monitoring
start_performance_timer() {
    local operation_name="$1"
    local start_time
    start_time=$(date +%s.%N)
    echo "$operation_name:$start_time"
}

end_performance_timer() {
    local timer_info="$1"
    local operation_name
    local start_time
    IFS=':' read -r operation_name start_time <<< "$timer_info"
    
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    robust_log "DEBUG" "Operation '$operation_name' completed in ${duration}s"
    
    # Check for performance issues
    if (( $(echo "$duration > 10.0" | bc -l 2>/dev/null || echo "0") )); then
        robust_log "WARN" "Slow operation detected: '$operation_name' took ${duration}s"
    fi
}

# Cleanup and resource management
cleanup_resources() {
    robust_log "INFO" "Performing resource cleanup..."
    
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Clean temporary files
    find /tmp -name "robust_*" -mtime +1 -delete 2>/dev/null || true
    
    # Reset terminal state
    if [[ -t 1 ]] && command -v stty >/dev/null 2>&1; then
        stty sane 2>/dev/null || true
    fi
    
    robust_log "INFO" "Resource cleanup completed"
}

#==============================================================================
# INITIALIZATION AND SHUTDOWN
#==============================================================================

# Initialize robustness framework
init_robustness_framework() {
    local log_file="${1:-$HOME/.gitswhy/robustness.log}"
    
    # Create log directory
    mkdir -p "$(dirname "$log_file")"
    LOG_FILE="$log_file"
    
    # Reset counters
    ERROR_COUNT=0
    WARNING_COUNT=0
    RECOVERY_ATTEMPTS=0
    OPERATION_TIMEOUTS=0
    COMMAND_FAILURES=0
    
    # Set up signal handlers
    trap 'cleanup_resources; exit 1' SIGINT SIGTERM
    trap 'cleanup_resources' EXIT
    
    robust_log "INFO" "Initializing ReflexCore Robustness Framework v$FRAMEWORK_VERSION"
    
    # Perform initial health check
    if ! check_system_health; then
        robust_log "WARN" "System health check failed, but continuing..."
    fi
    
    # Validate dependencies
    if ! validate_dependencies; then
        robust_log "ERROR" "Critical dependency validation failed"
        return 1
    fi
    
    robust_log "INFO" "Robustness framework initialized successfully"
    return 0
}

# Generate robustness report
generate_robustness_report() {
    local report_file="${1:-$HOME/.gitswhy/robustness_report.txt}"
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))
    
    robust_log "INFO" "Generating robustness report..."
    
    cat > "$report_file" << EOF
ReflexCore Robustness Report
Generated: $(date)
Duration: ${duration}s

System Health: $SYSTEM_HEALTH_STATUS
Error Count: $ERROR_COUNT
Warning Count: $WARNING_COUNT
Recovery Attempts: $RECOVERY_ATTEMPTS
Command Failures: $COMMAND_FAILURES
Operation Timeouts: $OPERATION_TIMEOUTS

Performance Metrics:
- Script Duration: ${duration}s
- Average Error Rate: $(echo "scale=2; $ERROR_COUNT / $duration" | bc -l 2>/dev/null || echo "0") errors/second
- Recovery Success Rate: $(echo "scale=2; $RECOVERY_ATTEMPTS > 0 ? ($RECOVERY_ATTEMPTS - $ERROR_COUNT) / $RECOVERY_ATTEMPTS * 100 : 100" | bc -l 2>/dev/null || echo "100")%

Last Error: $LAST_ERROR
Last Error Code: $LAST_ERROR_CODE

Recommendations:
$(if [[ $ERROR_COUNT -gt 0 ]]; then echo "- Review error logs for patterns"; fi)
$(if [[ $WARNING_COUNT -gt 5 ]]; then echo "- Address warning conditions"; fi)
$(if [[ $COMMAND_FAILURES -gt 0 ]]; then echo "- Check system dependencies"; fi)
$(if [[ $OPERATION_TIMEOUTS -gt 0 ]]; then echo "- Consider increasing timeouts"; fi)
EOF
    
    robust_log "INFO" "Robustness report generated: $report_file"
}

#==============================================================================
# EXPORT FUNCTIONS
#==============================================================================

# Export all robustness functions for use in other scripts
export -f robust_log
export -f robust_execute
export -f check_system_health
export -f validate_dependencies
export -f monitor_resources
export -f recover_from_error
export -f start_performance_timer
export -f end_performance_timer
export -f cleanup_resources
export -f init_robustness_framework
export -f generate_robustness_report

# Export configuration variables
export ERROR_LEVEL_FATAL ERROR_LEVEL_ERROR ERROR_LEVEL_WARN ERROR_LEVEL_INFO ERROR_LEVEL_DEBUG
export RECOVERY_RETRY RECOVERY_FALLBACK RECOVERY_SKIP RECOVERY_EXIT
export DEFAULT_TIMEOUT COMMAND_TIMEOUT NETWORK_TIMEOUT FILE_OPERATION_TIMEOUT
export MAX_RETRIES RETRY_DELAY BACKOFF_MULTIPLIER 