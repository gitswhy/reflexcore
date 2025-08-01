#!/bin/bash

# Simple test script to debug Core Mirror terminal issues
set -euo pipefail

echo "🔍 Core Mirror Terminal Debug Test"
echo "=================================="

# Check if we're in an interactive terminal
echo "1. Checking terminal type..."
if [[ -t 0 ]]; then
    echo "✅ Running in interactive terminal"
else
    echo "❌ Not running in interactive terminal"
fi

# Check available commands
echo -e "\n2. Checking required commands..."
for cmd in stty dd bc timeout; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd: $(which $cmd)"
    else
        echo "❌ $cmd: Not found"
    fi
done

# Test stty functionality
echo -e "\n3. Testing stty functionality..."
if command -v stty >/dev/null 2>&1; then
    echo "Current terminal settings:"
    stty -a 2>/dev/null | head -5 || echo "Failed to get terminal settings"
    
    echo -e "\nTesting stty -g..."
    if ORIGINAL_SETTINGS=$(stty -g 2>/dev/null); then
        echo "✅ Successfully saved terminal settings"
        echo "Settings: $ORIGINAL_SETTINGS"
    else
        echo "❌ Failed to save terminal settings"
    fi
else
    echo "❌ stty command not available"
fi

# Test dd functionality
echo -e "\n4. Testing dd functionality..."
if command -v dd >/dev/null 2>&1; then
    echo "Testing dd with timeout..."
    if command -v timeout >/dev/null 2>&1; then
        echo "Press a key within 3 seconds (or wait for timeout)..."
        if char=$(timeout 3s dd bs=1 count=1 2>/dev/null); then
            echo "✅ dd succeeded, read: '$char'"
        else
            echo "❌ dd timed out or failed"
        fi
    else
        echo "⚠️  timeout command not available, skipping dd test"
    fi
else
    echo "❌ dd command not available"
fi

# Test read functionality
echo -e "\n5. Testing read functionality..."
echo "Press a key within 3 seconds (or wait for timeout)..."
if read -t 3 -n 1 char; then
    echo "✅ read succeeded, read: '$char'"
else
    echo "❌ read timed out or failed"
fi

# Test the actual script
echo -e "\n6. Testing Core Mirror script..."
echo "Running: bash modules/gitswhy_coremirror.sh status"
bash modules/gitswhy_coremirror.sh status

echo -e "\n🎯 Debug test completed!"
echo "If you see any ❌ marks above, those are the issues causing the hang." 