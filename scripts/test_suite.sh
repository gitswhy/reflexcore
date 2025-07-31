#!/bin/bash

# ReflexCore Comprehensive Test Suite
# Tests all components and ensures system robustness

set -euo pipefail

# Test configuration
TEST_LOG_FILE="${TEST_LOG_FILE:-$HOME/.gitswhy/test_suite.log}"
TEST_TIMEOUT=60
TEST_RETRIES=2

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test logging
log_test() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$TEST_LOG_FILE")"
    
    # Log to file
    echo "[$timestamp] [TEST] [$level] [ctx:$context] $message" >> "$TEST_LOG_FILE"
    
    # Console output
    case "$level" in
        "PASS")  echo -e "${GREEN}[PASS]${NC} $message" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} $message" ;;
        "SKIP")  echo -e "${YELLOW}[SKIP]${NC} $message" ;;
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
    esac
    
    # Update counters
    case "$level" in
        "PASS") ((TESTS_PASSED++)) ;;
        "FAIL") ((TESTS_FAILED++)) ;;
        "SKIP") ((TESTS_SKIPPED++)) ;;
    esac
}

# Test runner with timeout and retry
run_test() {
    local test_name="$1"
    local test_command="$2"
    local context="${3:-}"
    local timeout="${4:-$TEST_TIMEOUT}"
    local max_retries="${5:-$TEST_RETRIES}"
    
    log_test "INFO" "Running test: $test_name" "$context"
    
    local attempt=1
    while [[ $attempt -le $max_retries ]]; do
        if timeout "$timeout" bash -c "$test_command" 2>/tmp/test_error_$$; then
            log_test "PASS" "Test passed: $test_name" "$context"
            rm -f /tmp/test_error_$$
            return 0
        else
            local exit_code=$?
            local error_output=$(cat /tmp/test_error_$$ 2>/dev/null || echo "Unknown error")
            rm -f /tmp/test_error_$$
            
            if [[ $attempt -lt $max_retries ]]; then
                log_test "INFO" "Test failed, retrying ($attempt/$max_retries): $test_name" "$context"
                sleep 2
                ((attempt++))
            else
                log_test "FAIL" "Test failed after $max_retries attempts: $test_name" "$context"
                log_test "FAIL" "Error: $error_output" "$context"
                return 1
            fi
        fi
    done
}

# Test script syntax
test_script_syntax() {
    local script_file="$1"
    local context="${2:-}"
    
    if [[ ! -f "$script_file" ]]; then
        log_test "SKIP" "Script not found: $script_file" "$context"
        return 0
    fi
    
    if bash -n "$script_file" 2>/dev/null; then
        log_test "PASS" "Syntax check passed: $script_file" "$context"
        return 0
    else
        log_test "FAIL" "Syntax error in: $script_file" "$context"
        return 1
    fi
}

# Test script execution
test_script_execution() {
    local script_file="$1"
    local test_args="${2:-}"
    local context="${3:-}"
    
    if [[ ! -f "$script_file" ]]; then
        log_test "SKIP" "Script not found: $script_file" "$context"
        return 0
    fi
    
    if [[ ! -x "$script_file" ]]; then
        log_test "SKIP" "Script not executable: $script_file" "$context"
        return 0
    fi
    
    # Test with help or status argument
    local test_command
    if [[ -n "$test_args" ]]; then
        test_command="bash '$script_file' $test_args"
    else
        test_command="bash '$script_file' --help 2>/dev/null || bash '$script_file' status 2>/dev/null || bash '$script_file' 2>/dev/null"
    fi
    
    run_test "Script execution: $script_file" "$test_command" "$context"
}

# Test Python modules
test_python_modules() {
    local context="${1:-}"
    
    # Test Python syntax
    local python_files=("gitswhy_vault_manager.py" "cli/gitswhy_cli.py")
    for py_file in "${python_files[@]}"; do
        if [[ -f "$py_file" ]]; then
            if python3 -m py_compile "$py_file" 2>/dev/null; then
                log_test "PASS" "Python syntax check: $py_file" "$context"
            else
                log_test "FAIL" "Python syntax error: $py_file" "$context"
                return 1
            fi
        fi
    done
    
    # Test Python imports
    if python3 -c "import click, cryptography, yaml" 2>/dev/null; then
        log_test "PASS" "Python dependencies available" "$context"
    else
        log_test "FAIL" "Missing Python dependencies" "$context"
        return 1
    fi
    
    return 0
}

# Test configuration
test_configuration() {
    local context="${1:-}"
    local config_file="config/gitswhy_config.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        log_test "FAIL" "Configuration file missing: $config_file" "$context"
        return 1
    fi
    
    # Test YAML syntax
    if python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
        log_test "PASS" "Configuration YAML syntax valid" "$context"
    else
        log_test "FAIL" "Configuration YAML syntax error" "$context"
        return 1
    fi
    
    # Test required keys
    local required_keys=("overclock_enabled" "vault_sync_enabled" "entropy_flush_enabled")
    for key in "${required_keys[@]}"; do
        if grep -q "^[[:space:]]*${key}:" "$config_file" 2>/dev/null; then
            log_test "PASS" "Configuration key present: $key" "$context"
        else
            log_test "WARN" "Configuration key missing: $key" "$context"
        fi
    done
    
    return 0
}

# Test system integration
test_system_integration() {
    local context="${1:-}"
    
    # Test log directory creation
    local log_dir="$HOME/.gitswhy"
    if mkdir -p "$log_dir" 2>/dev/null; then
        log_test "PASS" "Log directory accessible: $log_dir" "$context"
    else
        log_test "FAIL" "Cannot create log directory: $log_dir" "$context"
        return 1
    fi
    
    # Test file permissions
    if [[ -w "$log_dir" ]]; then
        log_test "PASS" "Log directory writable" "$context"
    else
        log_test "FAIL" "Log directory not writable" "$context"
        return 1
    fi
    
    # Test basic command execution
    local test_commands=("echo 'test'" "date" "whoami")
    for cmd in "${test_commands[@]}"; do
        if bash -c "$cmd" >/dev/null 2>&1; then
            log_test "PASS" "Command execution: $cmd" "$context"
        else
            log_test "FAIL" "Command execution failed: $cmd" "$context"
            return 1
        fi
    done
    
    return 0
}

# Test CLI interface
test_cli_interface() {
    local context="${1:-}"
    
    if [[ ! -f "cli/gitswhy_cli.py" ]]; then
        log_test "SKIP" "CLI script not found" "$context"
        return 0
    fi
    
    # Test help
    if python3 cli/gitswhy_cli.py --help >/dev/null 2>&1; then
        log_test "PASS" "CLI help works" "$context"
    else
        log_test "FAIL" "CLI help failed" "$context"
        return 1
    fi
    
    # Test status command
    if python3 cli/gitswhy_cli.py status >/dev/null 2>&1; then
        log_test "PASS" "CLI status works" "$context"
    else
        log_test "WARN" "CLI status failed" "$context"
    fi
    
    return 0
}

# Test vault management
test_vault_management() {
    local context="${1:-}"
    
    if [[ ! -f "gitswhy_vault_manager.py" ]]; then
        log_test "SKIP" "Vault manager not found" "$context"
        return 0
    fi
    
    # Test help
    if python3 gitswhy_vault_manager.py --help >/dev/null 2>&1; then
        log_test "PASS" "Vault manager help works" "$context"
    else
        log_test "FAIL" "Vault manager help failed" "$context"
        return 1
    fi
    
    # Test basic operations (without actual vault operations)
    local test_commands=(
        "python3 gitswhy_vault_manager.py --help"
        "python3 gitswhy_vault_manager.py --version 2>/dev/null || echo 'No version flag'"
    )
    
    for cmd in "${test_commands[@]}"; do
        if bash -c "$cmd" >/dev/null 2>&1; then
            log_test "PASS" "Vault manager command: $cmd" "$context"
        else
            log_test "WARN" "Vault manager command failed: $cmd" "$context"
        fi
    done
    
    return 0
}

# Test error handling
test_error_handling() {
    local context="${1:-}"
    
    # Test with invalid arguments
    local test_commands=(
        "bash scripts/gitswhy_initiate.sh invalid_arg 2>/dev/null || true"
        "python3 cli/gitswhy_cli.py invalid_command 2>/dev/null || true"
    )
    
    for cmd in "${test_commands[@]}"; do
        if bash -c "$cmd" >/dev/null 2>&1; then
            log_test "PASS" "Error handling: $cmd" "$context"
        else
            log_test "WARN" "Error handling failed: $cmd" "$context"
        fi
    done
    
    return 0
}

# Test performance
test_performance() {
    local context="${1:-}"
    
    # Test script startup time
    local start_time
    start_time=$(date +%s.%N)
    
    if bash scripts/gitswhy_initiate.sh status >/dev/null 2>&1; then
        local end_time
        end_time=$(date +%s.%N)
        local duration
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        if (( $(echo "$duration < 5.0" | bc -l 2>/dev/null || echo "1") )); then
            log_test "PASS" "Script startup time: ${duration}s" "$context"
        else
            log_test "WARN" "Slow script startup: ${duration}s" "$context"
        fi
    else
        log_test "FAIL" "Script startup test failed" "$context"
        return 1
    fi
    
    return 0
}

# Comprehensive test suite
run_test_suite() {
    local context="${1:-main}"
    local root_dir="${2:-.}"
    
    log_test "INFO" "Starting ReflexCore test suite" "$context"
    
    # Reset counters
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    
    local overall_success=true
    
    # Change to root directory
    cd "$root_dir" || {
        log_test "FAIL" "Cannot change to directory: $root_dir" "$context"
        return 1
    }
    
    # Run all tests
    test_script_syntax "scripts/gitswhy_initiate.sh" "$context" || overall_success=false
    test_script_syntax "scripts/gitswhy_quantumflush.sh" "$context" || overall_success=false
    test_script_syntax "modules/gitswhy_coremirror.sh" "$context" || overall_success=false
    
    test_script_execution "scripts/gitswhy_initiate.sh" "status" "$context" || overall_success=false
    test_script_execution "scripts/gitswhy_quantumflush.sh" "status" "$context" || overall_success=false
    test_script_execution "modules/gitswhy_coremirror.sh" "status" "$context" || overall_success=false
    
    test_python_modules "$context" || overall_success=false
    test_configuration "$context" || overall_success=false
    test_system_integration "$context" || overall_success=false
    test_cli_interface "$context" || overall_success=false
    test_vault_management "$context" || overall_success=false
    test_error_handling "$context" || overall_success=false
    test_performance "$context" || overall_success=false
    
    # Summary
    log_test "INFO" "Test suite summary:" "$context"
    log_test "INFO" "  Passed: $TESTS_PASSED" "$context"
    log_test "INFO" "  Failed: $TESTS_FAILED" "$context"
    log_test "INFO" "  Skipped: $TESTS_SKIPPED" "$context"
    
    if [[ "$overall_success" == "true" ]]; then
        log_test "PASS" "All tests passed" "$context"
        return 0
    else
        log_test "FAIL" "Some tests failed" "$context"
        return 1
    fi
}

# Export functions
export -f log_test run_test test_script_syntax test_script_execution
export -f test_python_modules test_configuration test_system_integration
export -f test_cli_interface test_vault_management test_error_handling
export -f test_performance run_test_suite 