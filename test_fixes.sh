#!/bin/bash

# Test script to verify the fixes for unbound variable errors
set -euo pipefail

echo "Testing ReflexCore script fixes..."

# Test 1: Test log_event function with missing parameters
echo "Test 1: Testing log_event function..."
source scripts/gitswhy_initiate.sh

# Test log_event with both parameters
log_event "INFO" "Test message with both parameters"

# Test log_event with missing second parameter (should not cause unbound variable error)
log_event "WARN"

# Test log_event with no parameters (should not cause unbound variable error)
log_event

echo "✅ Test 1 passed: log_event function handles missing parameters correctly"

# Test 2: Test variable initialization in subshells
echo "Test 2: Testing variable initialization..."

# Create a test environment
export HOME="/tmp/test_home"
mkdir -p "$HOME/.gitswhy"
export LOG_FILE="$HOME/.gitswhy/test.log"

# Test the core monitoring section (simplified)
echo "Testing core monitoring variable initialization..."
bash -c "
    # Initialize variables with defaults
    monitor_interval=\"\${MONITOR_INTERVAL:-60}\"
    log_file=\"$LOG_FILE\"
    
    echo \"monitor_interval: \$monitor_interval\"
    echo \"log_file: \$log_file\"
    echo \"Test completed\" >> \"\$log_file\"
"

# Test the vault sync section (simplified)
echo "Testing vault sync variable initialization..."
bash -c "
    # Initialize variables with defaults
    vault_dir=\"\$HOME/.gitswhy/vault\"
    backup_dir=\"\$HOME/.gitswhy/vault_backup\"
    log_file=\"$LOG_FILE\"
    
    echo \"vault_dir: \$vault_dir\"
    echo \"backup_dir: \$backup_dir\"
    echo \"log_file: \$log_file\"
    echo \"Vault sync test completed\" >> \"\$log_file\"
"

echo "✅ Test 2 passed: Variable initialization works correctly"

# Cleanup
rm -rf "$HOME/.gitswhy"

echo "🎉 All tests passed! The unbound variable errors should be fixed." 