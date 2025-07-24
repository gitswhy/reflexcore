#!/bin/bash

#==============================================================================
# Gitswhy OS - Quantum Flush Script
# File: scripts/gitswhy_quantumflush.sh
# Description: Flushes system entropy, DNS caches, network state, and UI sludge
# Author: ReflexCore Development Team
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#==============================================================================
# CONFIGURATION AND CONSTANTS
#==============================================================================

# Script metadata
SCRIPT_NAME="GitswhyQuantumFlush"
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
NC='\033[0m' # No Color

# Default values if config is missing
DEFAULT_DNS_FLUSH=true
DEFAULT_NETWORK_FLUSH=true
DEFAULT_UI_RESET=true
DEFAULT_ENTROPY_REFRESH=true

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Log function with timestamps
log_action() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    echo "[$timestamp] [QUANTUM] [$level] $message" >> "$LOG_FILE"
    
    # Also output to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        "FLUSH") echo -e "${PURPLE}[FLUSH]${NC} $message" ;;
        *)       echo "[UNKNOWN] $message" ;;
    esac
}

# Check if running as root or with sudo capabilities
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        SUDO_PREFIX=""
        log_action "WARN" "Not running as root. Privileged operations will be skipped."
    else
        SUDO_PREFIX=""
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a service exists and is active
service_exists() {
    local service_name="$1"
    systemctl list-units --full -all | grep -Fq "$service_name.service" 2>/dev/null
}

# Parse YAML configuration
parse_yaml_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_action "WARN" "Configuration file not found: $config_file - using defaults"
        DNS_FLUSH_ENABLED=$DEFAULT_DNS_FLUSH
        NETWORK_FLUSH_ENABLED=$DEFAULT_NETWORK_FLUSH
        UI_RESET_ENABLED=$DEFAULT_UI_RESET
        ENTROPY_REFRESH_ENABLED=$DEFAULT_ENTROPY_REFRESH
        return 0
    fi
    
    # Always check top-level *_enabled flags first
    DNS_FLUSH_ENABLED=$(grep -E "^\s*dns_flush_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    NETWORK_FLUSH_ENABLED=$(grep -E "^\s*network_flush_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    UI_RESET_ENABLED=$(grep -E "^\s*ui_reset_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    ENTROPY_REFRESH_ENABLED=$(grep -E "^\s*entropy_refresh_enabled:" "$config_file" | head -1 | sed 's/.*:\s*//' | tr -d ' ')
    
    # Fallback to defaults if not found
    DNS_FLUSH_ENABLED=${DNS_FLUSH_ENABLED:-"true"}
    NETWORK_FLUSH_ENABLED=${NETWORK_FLUSH_ENABLED:-"true"}
    UI_RESET_ENABLED=${UI_RESET_ENABLED:-"true"}
    ENTROPY_REFRESH_ENABLED=${ENTROPY_REFRESH_ENABLED:-"true"}
    
    # Debug output for config flags
    echo "[DEBUG] dns_flush_enabled=$DNS_FLUSH_ENABLED" >&2
    echo "[DEBUG] network_flush_enabled=$NETWORK_FLUSH_ENABLED" >&2
    echo "[DEBUG] ui_reset_enabled=$UI_RESET_ENABLED" >&2
    echo "[DEBUG] entropy_refresh_enabled=$ENTROPY_REFRESH_ENABLED" >&2
    log_action "INFO" "Configuration loaded: DNS=$DNS_FLUSH_ENABLED, Network=$NETWORK_FLUSH_ENABLED, UI=$UI_RESET_ENABLED, Entropy=$ENTROPY_REFRESH_ENABLED"
}

# Display system status before flush
show_system_status() {
    log_action "INFO" "System status before quantum flush:"
    
    # DNS cache status
    if command_exists resolvectl; then
        local cache_size=$(resolvectl statistics 2>/dev/null | grep "Current Cache Size" | awk '{print $4}' || echo "unknown")
        log_action "DEBUG" "DNS Cache Size: $cache_size entries"
    fi
    
    # Network status
    local network_connections=$(ss -tuln 2>/dev/null | wc -l || echo "unknown")
    log_action "DEBUG" "Active network connections: $network_connections"
    
    # Entropy status
    if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
        local entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        log_action "DEBUG" "Available entropy: $entropy bits"
    fi
    
    # Memory status
    local mem_used=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
    log_action "DEBUG" "Memory usage: ${mem_used}%"
}

#==============================================================================
# DNS & mDNS FLUSH FUNCTIONS
#==============================================================================

# Flush DNS caches and restart DNS services
flush_dns_services() {
    if [[ "$DNS_FLUSH_ENABLED" != "true" ]]; then
        log_action "INFO" "DNS flush disabled in configuration"
        return 0
    fi
    
    log_action "FLUSH" "Initiating DNS and mDNS service flush..."
    
    # Flush systemd-resolved cache (modern Ubuntu/Debian systems)
    if command_exists resolvectl; then
        log_action "INFO" "Flushing systemd-resolved cache..."
        if $SUDO_PREFIX resolvectl flush-caches 2>/dev/null; then
            log_action "INFO" "✓ systemd-resolved cache flushed successfully"
        else
            log_action "WARN" "Failed to flush systemd-resolved cache"
        fi
    elif command_exists systemd-resolve; then
        log_action "INFO" "Flushing systemd-resolve cache..."
        if $SUDO_PREFIX systemd-resolve --flush-caches 2>/dev/null; then
            log_action "INFO" "✓ systemd-resolve cache flushed successfully"
        else
            log_action "WARN" "Failed to flush systemd-resolve cache"
        fi
    fi
    
    # Restart systemd-resolved service
    if service_exists "systemd-resolved"; then
        log_action "INFO" "Restarting systemd-resolved service..."
        if $SUDO_PREFIX systemctl restart systemd-resolved 2>/dev/null; then
            log_action "INFO" "✓ systemd-resolved service restarted"
        else
            log_action "ERROR" "Failed to restart systemd-resolved"
        fi
    fi
    
    # Handle NSCD (Name Service Cache Daemon)
    if service_exists "nscd"; then
        log_action "INFO" "Restarting NSCD service..."
        if $SUDO_PREFIX systemctl restart nscd 2>/dev/null; then
            log_action "INFO" "✓ NSCD service restarted"
        else
            log_action "WARN" "Failed to restart NSCD"
        fi
    fi
    
    # Handle dnsmasq service
    if service_exists "dnsmasq"; then
        log_action "INFO" "Restarting dnsmasq service..."
        if $SUDO_PREFIX systemctl restart dnsmasq 2>/dev/null; then
            log_action "INFO" "✓ dnsmasq service restarted"
        else
            log_action "WARN" "Failed to restart dnsmasq"
        fi
    fi
    
    # Handle BIND9 DNS server
    if service_exists "bind9"; then
        log_action "INFO" "Restarting BIND9 DNS service..."
        if $SUDO_PREFIX systemctl restart bind9 2>/dev/null; then
            log_action "INFO" "✓ BIND9 service restarted"
        elif command_exists rndc; then
            log_action "INFO" "Flushing BIND9 cache with rndc..."
            if $SUDO_PREFIX rndc flush 2>/dev/null; then
                log_action "INFO" "✓ BIND9 cache flushed"
            else
                log_action "WARN" "Failed to flush BIND9 cache"
            fi
        fi
    fi
    
    # Handle Avahi (mDNS/Zeroconf)
    if service_exists "avahi-daemon"; then
        log_action "INFO" "Restarting Avahi mDNS daemon..."
        if $SUDO_PREFIX systemctl restart avahi-daemon 2>/dev/null; then
            log_action "INFO" "✓ Avahi mDNS daemon restarted"
        else
            log_action "WARN" "Failed to restart Avahi daemon"
        fi
    fi
    
    log_action "FLUSH" "DNS services flush completed"
}

#==============================================================================
# NETWORK CACHE FLUSH FUNCTIONS
#==============================================================================

# Clear network caches and reset network state
flush_network_caches() {
    if [[ "$NETWORK_FLUSH_ENABLED" != "true" ]]; then
        log_action "INFO" "Network flush disabled in configuration"
        return 0
    fi
    
    log_action "FLUSH" "Initiating network cache flush..."
    
    # Clear ARP cache
    log_action "INFO" "Clearing ARP cache..."
    if $SUDO_PREFIX ip -s -s neigh flush all 2>/dev/null; then
        log_action "INFO" "✓ ARP cache cleared"
    else
        log_action "WARN" "Failed to clear ARP cache"
    fi
    
    # Clear routing cache
    log_action "INFO" "Clearing routing cache..."
    if $SUDO_PREFIX ip route flush cache 2>/dev/null; then
        log_action "INFO" "✓ Routing cache cleared"
    else
        log_action "WARN" "Failed to clear routing cache"
    fi
    
    # Flush network buffers
    log_action "INFO" "Synchronizing network buffers..."
    sync
    
    # Clear netfilter connection tracking (if available)
    if [[ -f "/proc/sys/net/netfilter/nf_conntrack_count" ]]; then
        log_action "INFO" "Clearing netfilter connection tracking..."
        echo 1 | $SUDO_PREFIX tee /proc/sys/net/netfilter/nf_conntrack_flush >/dev/null 2>&1 || \
            log_action "DEBUG" "Netfilter flush not available or failed"
    fi
    
    # Reset network statistics
    if command_exists ss; then
        local before_connections=$(ss -tuln 2>/dev/null | wc -l)
        log_action "DEBUG" "Network connections before flush: $before_connections"
    fi
    
    # Restart NetworkManager (if available and safe)
    if service_exists "NetworkManager" && [[ "${RESTART_NETWORK_MANAGER:-false}" == "true" ]]; then
        log_action "INFO" "Restarting NetworkManager..."
        if $SUDO_PREFIX systemctl restart NetworkManager 2>/dev/null; then
            log_action "INFO" "✓ NetworkManager restarted"
            sleep 3  # Allow time for network to stabilize
        else
            log_action "WARN" "Failed to restart NetworkManager"
        fi
    fi
    
    log_action "FLUSH" "Network cache flush completed"
}

#==============================================================================
# UI SLUDGE RESET FUNCTIONS
#==============================================================================

# Reset UI components and clear GUI caches
reset_ui_sludge() {
    if [[ "$UI_RESET_ENABLED" != "true" ]]; then
        log_action "INFO" "UI reset disabled in configuration"
        return 0
    fi
    
    log_action "FLUSH" "Initiating UI sludge reset..."
    
    # Clear X11 clipboard and selection buffers
    if [[ -n "${DISPLAY:-}" ]]; then
        log_action "INFO" "Clearing X11 clipboard buffers..."
        if command_exists xsel; then
            xsel -bc 2>/dev/null && xsel -pc 2>/dev/null && xsel -sc 2>/dev/null
            log_action "INFO" "✓ X11 clipboard cleared"
        elif command_exists xclip; then
            echo -n "" | xclip -selection clipboard 2>/dev/null
            echo -n "" | xclip -selection primary 2>/dev/null
            log_action "INFO" "✓ X11 clipboard cleared with xclip"
        fi
    fi
    
    # Clear GNOME Shell cache and restart (if running)
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] && command_exists gnome-shell; then
        log_action "INFO" "Clearing GNOME Shell cache..."
        rm -rf ~/.cache/gnome-shell/ 2>/dev/null || true
        
        # Reset GNOME settings to clear UI sludge (careful - this resets customizations)
        if [[ "${RESET_GNOME_SETTINGS:-false}" == "true" ]]; then
            log_action "WARN" "Resetting GNOME desktop settings (this will clear customizations)"
            dconf reset -f /org/gnome/shell/ 2>/dev/null || true
            dconf reset -f /org/gnome/desktop/background/ 2>/dev/null || true
        fi
        
        log_action "INFO" "✓ GNOME Shell cache cleared"
    fi
    
    # Clear KDE Plasma cache
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        log_action "INFO" "Clearing KDE Plasma cache..."
        rm -rf ~/.cache/kioexec/ 2>/dev/null || true
        rm -rf ~/.cache/plasma* 2>/dev/null || true
        log_action "INFO" "✓ KDE Plasma cache cleared"
    fi
    
    # Clear general desktop cache directories
    log_action "INFO" "Clearing general UI caches..."
    local cache_dirs=(
        "$HOME/.cache/thumbnails/"
        "$HOME/.cache/fontconfig/"
        "$HOME/.cache/mesa_shader_cache/"
        "$HOME/.cache/nvidia/"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            rm -rf "$cache_dir"* 2>/dev/null || true
            log_action "DEBUG" "Cleared cache: $cache_dir"
        fi
    done
    
    # Reset terminal state
    if [[ -t 1 ]]; then
        reset 2>/dev/null || true
        log_action "DEBUG" "Terminal state reset"
    fi
    
    log_action "FLUSH" "UI sludge reset completed"
}

#==============================================================================
# ENTROPY REFRESH FUNCTIONS
#==============================================================================

# Refresh system entropy pool
refresh_system_entropy() {
    if [[ "$ENTROPY_REFRESH_ENABLED" != "true" ]]; then
        log_action "INFO" "Entropy refresh disabled in configuration"
        return 0
    fi
    
    log_action "FLUSH" "Initiating entropy pool refresh..."
    
    # Check current entropy level
    if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
        local entropy_before=$(cat /proc/sys/kernel/random/entropy_avail)
        log_action "INFO" "Current entropy pool: $entropy_before bits"
    fi
    
    # Generate entropy through system activity
    log_action "INFO" "Generating fresh entropy through system activity..."
    
    # Method 1: Use /dev/urandom to stir the entropy pool
    dd if=/dev/urandom of=/dev/null bs=1024 count=10 2>/dev/null &
    local dd_pid=$!
    
    # Method 2: File system activity to generate interrupts
    find /proc -type f -name "stat" -exec cat {} \; >/dev/null 2>&1 &
    local find_pid=$!
    
    # Method 3: Generate network activity
    ping -c 3 localhost >/dev/null 2>&1 &
    local ping_pid=$!
    
    # Wait for entropy generation activities (max 10 seconds)
    local timeout=10
    local count=0
    while [[ $(jobs -r | wc -l) -gt 0 ]] && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    # Clean up any remaining processes
    kill $dd_pid $find_pid $ping_pid 2>/dev/null || true
    wait 2>/dev/null || true
    
    # Check entropy after refresh
    if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
        local entropy_after=$(cat /proc/sys/kernel/random/entropy_avail)
        log_action "INFO" "Entropy pool after refresh: $entropy_after bits"
        
        if [[ $entropy_after -gt ${entropy_before:-0} ]]; then
            log_action "INFO" "✓ Entropy pool refreshed successfully"
        else
            log_action "DEBUG" "Entropy levels maintained"
        fi
    fi
    
    # Trigger entropy estimation recalculation
    if [[ -w "/proc/sys/kernel/random/write_wakeup_threshold" ]]; then
        echo 1024 | $SUDO_PREFIX tee /proc/sys/kernel/random/write_wakeup_threshold >/dev/null 2>&1 || true
    fi
    
    log_action "FLUSH" "Entropy refresh completed"
}

#==============================================================================
# VERIFICATION FUNCTIONS
#==============================================================================

# Verify system flush was successful
verify_flush_success() {
    log_action "INFO" "Verifying quantum flush success..."
    
    local verification_passed=true
    
    # Verify DNS cache was cleared
    if command_exists resolvectl; then
        local cache_size=$(resolvectl statistics 2>/dev/null | grep "Current Cache Size" | awk '{print $4}' || echo "0")
        if [[ "${cache_size:-0}" -eq 0 ]]; then
            log_action "INFO" "✓ DNS cache verified as cleared"
        else
            log_action "WARN" "⚠ DNS cache may not be completely cleared (size: $cache_size)"
        fi
    fi
    
    # Verify network state
    sleep 2  # Allow time for network changes to take effect
    local network_connections=$(ss -tuln 2>/dev/null | wc -l || echo "0")
    log_action "DEBUG" "Current network connections: $network_connections"
    
    # Check entropy levels
    if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
        local current_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        if [[ $current_entropy -gt 100 ]]; then
            log_action "INFO" "✓ Entropy pool verified as healthy ($current_entropy bits)"
        else
            log_action "WARN" "⚠ Low entropy levels ($current_entropy bits)"
            verification_passed=false
        fi
    fi
    
    # Check system responsiveness
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_action "DEBUG" "System load average: $load_avg"
    
    if [[ "$verification_passed" == "true" ]]; then
        log_action "INFO" "✓ Quantum flush verification completed successfully"
        return 0
    else
        log_action "WARN" "⚠ Some verification checks failed"
        return 1
    fi
}

#==============================================================================
# MAIN EXECUTION FLOW
#==============================================================================

main() {
    log_action "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Check system requirements
    check_privileges
    
    # Parse configuration file
    parse_yaml_config "$CONFIG_FILE"
    
    # Display system status before flush
    show_system_status
    
    log_action "FLUSH" "Initiating quantum system flush sequence..."
    
    # Execute flush operations
    flush_dns_services
    flush_network_caches
    reset_ui_sludge
    refresh_system_entropy
    
    # Verify flush success
    if verify_flush_success; then
        log_action "INFO" "Quantum flush completed successfully"
    else
        log_action "WARN" "Quantum flush completed with some warnings"
    fi
    
    # Final success message
    echo -e "${GREEN}[GitsWhy] Flush complete.${NC}"
    log_action "INFO" "Quantum flush operation completed"
    
    # Display summary
    echo ""
    echo "=== Quantum Flush Summary ==="
    echo "• DNS Services: $([ "$DNS_FLUSH_ENABLED" = "true" ] && echo "✓ Flushed" || echo "✗ Skipped")"
    echo "• Network Caches: $([ "$NETWORK_FLUSH_ENABLED" = "true" ] && echo "✓ Cleared" || echo "✗ Skipped")"
    echo "• UI Sludge: $([ "$UI_RESET_ENABLED" = "true" ] && echo "✓ Reset" || echo "✗ Skipped")"
    echo "• Entropy Pool: $([ "$ENTROPY_REFRESH_ENABLED" = "true" ] && echo "✓ Refreshed" || echo "✗ Skipped")"
    if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
        echo "• Current Entropy: $(cat /proc/sys/kernel/random/entropy_avail) bits"
    fi
    echo "• Log file: $LOG_FILE"
    echo ""
}

# Handle script arguments
case "${1:-flush}" in
    "flush"|"start"|"")
        main
        ;;
    "status")
        echo "Current system status:"
        if command_exists resolvectl; then
            echo "DNS Cache Size: $(resolvectl statistics 2>/dev/null | grep "Current Cache Size" | awk '{print $4}' || echo "unknown")"
        fi
        echo "Network Connections: $(ss -tuln 2>/dev/null | wc -l || echo "unknown")"
        if [[ -f "/proc/sys/kernel/random/entropy_avail" ]]; then
            echo "Available Entropy: $(cat /proc/sys/kernel/random/entropy_avail) bits"
        fi
        echo "Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", ($3/$2)*100}')"
        ;;
    "test")
        echo "Running quantum flush test sequence..."
        main
        ;;
    *)
        echo "Usage: $0 {flush|status|test}"
        echo "  flush  - Perform quantum system flush (default)"
        echo "  status - Show current system status"
        echo "  test   - Run test flush sequence"
        exit 1
        ;;
esac 