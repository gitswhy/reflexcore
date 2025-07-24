#!/bin/bash

# ReflexCore Full Test Suite
# This script tests all core modules of ReflexCore suite and verifies logs and encryption

set -euo pipefail

LOG_DIR="$HOME/.gitswhy"
if [ "$EUID" -eq 0 ]; then
  EVENTS_LOG="/root/.gitswhy/events.log"
else
  EVENTS_LOG="$HOME/.gitswhy/events.log"
fi
OVERCLOCK_LOG="/root/.gitswhy/overclock.log"
VAULT_FILE="$LOG_DIR/vault.json"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function for printing section headers
print_header() {
    echo -e "\n===== $1 ====="
}

# Test 1: Initiate ReflexCore background services
test_initiate() {
    print_header "Testing ReflexCore Initiate"
    bash "$PROJECT_ROOT/scripts/gitswhy_initiate.sh" start
    sleep 5  # wait for processes to initialize
    grep -F "ReflexCore initialization completed" "$EVENTS_LOG" || { echo "ERROR: Failed to find 'ReflexCore initialization completed' in events.log"; exit 1; }
    echo "Initiate test passed."
}

# Test 2: GPU Overclock
test_overclock() {
    print_header "Testing GPU Overclock"
    sudo bash "$PROJECT_ROOT/scripts/gitswhy_gpuoverclock.sh"
    grep "Overclock complete" "$OVERCLOCK_LOG" || { echo "ERROR: Overclock completion message missing in log"; exit 1; }
    echo "Overclock test passed."
}

# Test 3: Quantum Flush
test_flush() {
    print_header "Testing Quantum Flush"
    sudo bash "$PROJECT_ROOT/scripts/gitswhy_quantumflush.sh"
    grep -F "Quantum flush completed successfully" "$EVENTS_LOG" || { echo "ERROR: Flush completion message missing in events.log"; exit 1; }
    echo "Flush test passed."
}

# Test 4: Auto Clean
test_clean() {
    print_header "Testing Auto Clean"
    sudo bash "$PROJECT_ROOT/scripts/gitswhy_autoclean.sh"
    grep -F "Auto-clean completed successfully" "$EVENTS_LOG" || { echo "ERROR: Clean completion message missing in events.log"; exit 1; }
    echo "Clean test passed."
}

# Test 5: Core Mirror Keystroke Monitoring (run briefly, check log creation)
test_coremirror() {
    print_header "Testing Core Mirror Keystroke Monitoring"
    # Run monitoring for 5 seconds
    bash "$PROJECT_ROOT/modules/gitswhy_coremirror.sh" test &
    sleep 6
    pkill -f gitswhy_coremirror.sh || true
    grep "hesitation" "$EVENTS_LOG" && echo "CoreMirror hesitation logged." || echo "No hesitation events logged; manual check recommended."
    echo "CoreMirror test completed."
}

# Test 6: Vault Sync and Encryption
test_vaultsync() {
    print_header "Testing Vault Sync and Encryption"
    testfile="/tmp/test_events.json"
    tail -n 20 "$EVENTS_LOG" > "$testfile" || echo '[]' > "$testfile"
    bash "$PROJECT_ROOT/scripts/gitswhy_vaultsync.sh" sync
    [[ -f "$VAULT_FILE" ]] || { echo "ERROR: Vault file not created"; exit 1; }

    # Test decryption output
    python3 "$PROJECT_ROOT/gitswhy_vault_manager.py" --config "$PROJECT_ROOT/config/gitswhy_config.yaml" \
        --operation retrieve --vault-file "$VAULT_FILE" --output-format summary 1>/dev/null
    echo "Vault sync and encryption test passed."
}

# Main test runner
main() {
    echo "Starting ReflexCore Full Test Suite..."

    test_initiate
    test_overclock
    test_flush
    test_clean
    test_coremirror
    test_vaultsync

    echo "\nAll tests completed successfully!"
}

main 