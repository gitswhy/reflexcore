#!/bin/bash

# ReflexCore Linting and Code Quality Checker
# Comprehensive script to check all shell scripts for issues

set -euo pipefail

# Configuration
LINT_LOG_FILE="${LINT_LOG_FILE:-$HOME/.gitswhy/lint_check.log}"
SHELLCHECK_SEVERITY="style"
SHELLCHECK_EXCLUDE="SC2034,SC2155,SC2162,SC2254,SC1090,SC1091"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Lint results
LINT_PASSED=0
LINT_FAILED=0
LINT_WARNINGS=0

# Logging function
log_lint() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LINT_LOG_FILE")"
    
    # Log to file
    echo "[$timestamp] [LINT] [$level] [ctx:$context] $message" >> "$LINT_LOG_FILE"
    
    # Console output
    case "$level" in
        "PASS")  echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
    esac
    
    # Update counters
    case "$level" in
        "PASS") ((LINT_PASSED++)) ;;
        "FAIL") ((LINT_FAILED++)) ;;
        "WARN") ((LINT_WARNINGS++)) ;;
    esac
}

# Check if ShellCheck is available
check_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        log_lint "FAIL" "ShellCheck not found. Install with: sudo apt install shellcheck"
        return 1
    fi
    
    local version
    version=$(shellcheck --version | head -1)
    log_lint "INFO" "ShellCheck version: $version"
    return 0
}

# Lint a single script file
lint_script() {
    local script_file="$1"
    local context="${2:-}"
    
    if [[ ! -f "$script_file" ]]; then
        log_lint "SKIP" "Script not found: $script_file" "$context"
        return 0
    fi
    
    log_lint "INFO" "Linting script: $script_file" "$context"
    
    # Check syntax first
    if ! bash -n "$script_file" 2>/dev/null; then
        log_lint "FAIL" "Syntax error in: $script_file" "$context"
        return 1
    fi
    
    # Run ShellCheck
    local shellcheck_output
    shellcheck_output=$(shellcheck --severity="$SHELLCHECK_SEVERITY" --exclude="$SHELLCHECK_EXCLUDE" "$script_file" 2>&1 || true)
    
    if [[ -z "$shellcheck_output" ]]; then
        log_lint "PASS" "ShellCheck passed: $script_file" "$context"
        return 0
    else
        # Count issues
        local error_count
        error_count=$(echo "$shellcheck_output" | grep -c "SC[0-9]*" || echo "0")
        local warning_count
        warning_count=$(echo "$shellcheck_output" | grep -c "warning:" || echo "0")
        
        if [[ $error_count -gt 0 ]]; then
            log_lint "FAIL" "ShellCheck found $error_count errors in: $script_file" "$context"
            echo "$shellcheck_output" | sed 's/^/  /'
            return 1
        elif [[ $warning_count -gt 0 ]]; then
            log_lint "WARN" "ShellCheck found $warning_count warnings in: $script_file" "$context"
            echo "$shellcheck_output" | sed 's/^/  /'
            return 0
        else
            log_lint "PASS" "ShellCheck passed: $script_file" "$context"
            return 0
        fi
    fi
}

# Comprehensive linting
run_comprehensive_lint() {
    local context="${1:-main}"
    local root_dir="${2:-.}"
    
    log_lint "INFO" "Starting comprehensive linting" "$context"
    
    # Reset counters
    LINT_PASSED=0
    LINT_FAILED=0
    LINT_WARNINGS=0
    
    # Check ShellCheck availability
    if ! check_shellcheck; then
        log_lint "FAIL" "Cannot proceed without ShellCheck" "$context"
        return 1
    fi
    
    local overall_success=true
    
    # Lint all script directories
    local script_dirs=("scripts" "modules")
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$root_dir/$dir" ]]; then
            local scripts
            mapfile -t scripts < <(find "$root_dir/$dir" -name "*.sh" -type f 2>/dev/null || true)
            
            for script in "${scripts[@]}"; do
                if ! lint_script "$script" "$context"; then
                    overall_success=false
                fi
            done
        fi
    done
    
    # Lint individual script files
    local individual_scripts=("make_executable.sh" "test_all.sh" "test_coremirror.sh" "test_fixes.sh")
    for script in "${individual_scripts[@]}"; do
        if [[ -f "$root_dir/$script" ]]; then
            if ! lint_script "$root_dir/$script" "$context"; then
                overall_success=false
            fi
        fi
    done
    
    # Summary
    log_lint "INFO" "Linting summary:" "$context"
    log_lint "INFO" "  Passed: $LINT_PASSED" "$context"
    log_lint "INFO" "  Failed: $LINT_FAILED" "$context"
    log_lint "INFO" "  Warnings: $LINT_WARNINGS" "$context"
    
    if [[ "$overall_success" == "true" ]]; then
        log_lint "PASS" "All scripts passed linting" "$context"
        return 0
    else
        log_lint "FAIL" "Some scripts failed linting" "$context"
        return 1
    fi
}

# Main function
main() {
    local mode="${1:-comprehensive}"
    local root_dir="${2:-.}"
    
    case "$mode" in
        "comprehensive")
            run_comprehensive_lint "main" "$root_dir"
            ;;
        "help")
            echo "Usage: $0 [comprehensive|help] [root_dir]"
            echo "  comprehensive: Run full linting on all scripts"
            echo "  help: Show this help message"
            ;;
        *)
            echo "Unknown mode: $mode"
            echo "Use 'help' for usage information"
            return 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 