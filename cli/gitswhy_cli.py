#!/usr/bin/env python3

"""
Gitswhy OS - Command Line Interface
File: cli/gitswhy_cli.py
Description: CLI wrapper for all Gitswhy ReflexCore modules using Click
Author: ReflexCore Development Team
Version: 1.0.0

This CLI provides a unified interface to all Gitswhy OS components including
system optimization, cache management, keystroke monitoring, and vault operations.
"""

import click
import os
import sys
import subprocess
import json
import platform
from pathlib import Path
from typing import Optional, Dict, Any

# Add project root to path for imports
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

try:
    from gitswhy_vault_manager import VaultManager
except ImportError:
    VaultManager = None

# Platform detection
IS_WINDOWS = platform.system().lower() == "windows"
IS_LINUX = platform.system().lower() == "linux"
IS_MACOS = platform.system().lower() == "darwin"

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_colored(message: str, color: str = Colors.GREEN) -> None:
    click.echo(f"{color}{message}{Colors.END}")

def run_script(script_path: str, args: list = None, sudo: bool = False) -> bool:
    """Run a shell script with platform-specific handling"""
    try:
        full_path = PROJECT_ROOT / script_path
        if not full_path.exists():
            print_colored(f"ERROR: Script not found: {full_path}", Colors.RED)
            return False
        
        # Windows compatibility check
        if IS_WINDOWS and script_path.endswith('.sh'):
            print_colored(f"⚠️  Shell script '{script_path}' not supported on Windows", Colors.YELLOW)
            print_colored("💡 Use WSL (Windows Subsystem for Linux) for full functionality", Colors.BLUE)
            return False
        
        cmd = []
        if sudo and not IS_WINDOWS:
            cmd.append('sudo')
        cmd.append(str(full_path))
        if args:
            cmd.extend(args)
        
        result = subprocess.run(cmd, capture_output=False, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print_colored(f"ERROR: Script execution failed: {e}", Colors.RED)
        return False
    except Exception as e:
        print_colored(f"ERROR: Unexpected error: {e}", Colors.RED)
        return False

def check_config_exists() -> bool:
    config_path = PROJECT_ROOT / "config" / "gitswhy_config.yaml"
    return config_path.exists()

def get_script_status(script_name: str) -> Dict[str, Any]:
    script_paths = {
        'init': 'scripts/gitswhy_initiate.sh',
        'overclock': 'scripts/gitswhy_gpuoverclock.sh',
        'flush': 'scripts/gitswhy_quantumflush.sh',
        'clean': 'scripts/gitswhy_autoclean.sh',
        'mirror': 'modules/keystroke_monitor_v2.sh',
        'syncvault': 'scripts/gitswhy_vaultsync.sh'
    }
    script_path = PROJECT_ROOT / script_paths.get(script_name, '')
    return {
        'name': script_name,
        'path': str(script_path),
        'exists': script_path.exists(),
        'executable': script_path.exists() and os.access(script_path, os.X_OK),
        'platform_supported': not (IS_WINDOWS and script_path.suffix == '.sh')
    }

@click.group()
@click.version_option(version="1.0.0", prog_name="Gitswhy ReflexCore CLI")
@click.option('--verbose', is_flag=True, help='Enable verbose output')
@click.option('--config', '-c', 
              default=str(PROJECT_ROOT / "config" / "gitswhy_config.yaml"),
              help='Path to configuration file')
@click.pass_context
def cli(ctx: click.Context, verbose: bool, config: str) -> None:
    """Unified CLI for Gitswhy ReflexCore. Use --help for all commands."""
    ctx.ensure_object(dict)
    ctx.obj['verbose'] = verbose
    ctx.obj['config'] = config
    ctx.obj['project_root'] = PROJECT_ROOT
    if verbose:
        print_colored(f"Platform: {platform.system()}", Colors.BLUE)
        print_colored(f"Project root: {PROJECT_ROOT}", Colors.BLUE)

@cli.command()
@click.option('--force', is_flag=True, help='Force initialization even if already configured')
@click.pass_context
def init(ctx: click.Context, force: bool) -> None:
    """Initialize ReflexCore background services and configuration."""
    print_colored("🚀 Initializing Gitswhy ReflexCore...", Colors.HEADER)
    
    if IS_WINDOWS:
        print_colored("⚠️  Windows detected - limited functionality available", Colors.YELLOW)
        print_colored("💡 Shell scripts require WSL (Windows Subsystem for Linux)", Colors.BLUE)
        print_colored("✅ Python components will work normally", Colors.GREEN)
    
    if not check_config_exists() and not force:
        print_colored("⚠️  Configuration file not found. Creating default config...", Colors.YELLOW)
    
    try:
        if IS_WINDOWS:
            # On Windows, just create the vault directory and show status
            vault_dir = Path.home() / ".gitswhy"
            vault_dir.mkdir(exist_ok=True)
            print_colored(f"✅ Created vault directory: {vault_dir}", Colors.GREEN)
            print_colored("✅ ReflexCore Python components initialized!", Colors.GREEN)
            print_colored("💡 Use 'python cli/gitswhy_cli.py status' to check system status", Colors.BLUE)
        else:
            # On Linux/macOS, run the full initialization script
            success = run_script('scripts/gitswhy_initiate.sh', ['start'])
            if success:
                print_colored("✅ ReflexCore initialization completed successfully!", Colors.GREEN)
            else:
                print_colored("❌ ReflexCore initialization failed!", Colors.RED)
                raise click.ClickException("Initialization failed")
    except Exception as e:
        if ctx.obj and ctx.obj.get('verbose'):
            print_colored(f"Error details: {e}", Colors.RED)
        raise click.ClickException(f"Failed to initialize ReflexCore: {e}")

@cli.command()
@click.option('--restore', is_flag=True, help='Restore original system parameters')
@click.pass_context
def overclock(ctx: click.Context, restore: bool) -> None:
    """Apply or restore system overclocking optimizations."""
    if IS_WINDOWS:
        print_colored("⚠️  System optimization not available on Windows", Colors.YELLOW)
        print_colored("💡 Use WSL for full system optimization features", Colors.BLUE)
        return
    
    if restore:
        print_colored("🔄 Restoring original system parameters...", Colors.YELLOW)
        success = run_script('scripts/gitswhy_gpuoverclock.sh', ['restore'], sudo=True)
    else:
        print_colored("⚡ Applying system overclocking optimizations...", Colors.HEADER)
        success = run_script('scripts/gitswhy_gpuoverclock.sh', [], sudo=True)
    if success:
        action = "restored" if restore else "applied"
        print_colored(f"✅ System parameters {action} successfully!", Colors.GREEN)
    else:
        print_colored("❌ Overclocking operation failed!", Colors.RED)
        raise click.ClickException("Overclocking operation failed")

@cli.command()
@click.option('--test', is_flag=True, help='Run test flush sequence')
@click.pass_context
def flush(ctx: click.Context, test: bool) -> None:
    """Initiate a quantum system flush to clear memory."""
    if IS_WINDOWS:
        print_colored("⚠️  System flush not available on Windows", Colors.YELLOW)
        print_colored("💡 Use WSL for system optimization features", Colors.BLUE)
        return
    
    print_colored("🌊 Initiating quantum system flush...", Colors.HEADER)
    args = ['test'] if test else ['flush']
    success = run_script('scripts/gitswhy_quantumflush.sh', args, sudo=True)
    if success:
        print_colored("✅ Quantum flush completed successfully!", Colors.GREEN)
    else:
        print_colored("❌ Quantum flush failed!", Colors.RED)
        raise click.ClickException("Quantum flush operation failed")

@cli.command()
@click.option('--aggressive', is_flag=True, help='Perform aggressive cleanup')
@click.pass_context
def clean(ctx: click.Context, aggressive: bool) -> None:
    """Perform aggressive system cleanup operations."""
    if IS_WINDOWS:
        print_colored("⚠️  System cleanup not available on Windows", Colors.YELLOW)
        print_colored("💡 Use WSL for system maintenance features", Colors.BLUE)
        return
    
    print_colored("🧹 Starting system cleanup operations...", Colors.HEADER)
    args = ['clean']
    success = run_script('scripts/gitswhy_autoclean.sh', args, sudo=True)
    if success:
        print_colored("✅ System cleanup completed successfully!", Colors.GREEN)
    else:
        print_colored("❌ System cleanup failed!", Colors.RED)
        raise click.ClickException("Auto-clean operation failed")

@cli.command()
@click.option('--timeout', type=int, default=60, help='Monitoring timeout in seconds')
@click.pass_context
def mirror(ctx: click.Context, timeout: int) -> None:
    """Start Core Mirror keystroke monitoring to track user activity."""
    if IS_WINDOWS:
        print_colored("⚠️  Running keystroke monitoring via WSL...", Colors.YELLOW)
        print_colored("💡 Make sure WSL is installed and Ubuntu is available", Colors.BLUE)
        print_colored("💡 For best results, run directly in WSL terminal:", Colors.CYAN)
        print_colored("   wsl -d Ubuntu", Colors.GREEN)
        print_colored("   cd /mnt/c/Users/Sujal\\ Malviya/reflexcore", Colors.GREEN)
        print_colored("   bash modules/keystroke_monitor_v2.sh", Colors.GREEN)
    
    print_colored("👁️  Starting Keystroke Monitor v2...", Colors.HEADER)
    print_colored(f"Monitoring timeout: {timeout} seconds", Colors.BLUE)
    
    try:
        if IS_WINDOWS:
            # Use WSL to run the script from the reflexcore directory
            wsl_path = "/mnt/c/Users/Sujal Malviya/reflexcore/modules/keystroke_monitor_v2.sh"
            # Don't use external timeout, let the script handle non-interactive mode
            cmd = ['wsl', '-d', 'Ubuntu', 'bash', wsl_path]
        else:
            cmd = ['timeout', str(timeout), str(PROJECT_ROOT / 'modules/keystroke_monitor_v2.sh')]
        
        result = subprocess.run(cmd, capture_output=False, text=True)
        if result.returncode == 0:
            print_colored("✅ Keystroke monitoring completed!", Colors.GREEN)
        elif result.returncode == 124:
            print_colored("⏰ Monitoring stopped due to timeout", Colors.YELLOW)
        else:
            print_colored("❌ Keystroke monitoring failed!", Colors.RED)
            if IS_WINDOWS:
                print_colored("💡 This is expected when running through WSL from PowerShell", Colors.CYAN)
                print_colored("💡 Try running directly in WSL terminal for full functionality", Colors.BLUE)
    except KeyboardInterrupt:
        print_colored("\n⏹️  Monitoring stopped by user", Colors.YELLOW)
    except Exception as e:
        if ctx.obj and ctx.obj.get('verbose'):
            print_colored(f"Error details: {e}", Colors.RED)
        raise click.ClickException(f"Mirror operation failed: {e}")

@cli.command()
@click.option('--force', is_flag=True, help='Force sync even if vault exists')
@click.pass_context
def syncvault(ctx: click.Context, force: bool) -> None:
    """Synchronize events to an encrypted vault for persistence."""
    if IS_WINDOWS:
        print_colored("⚠️  Vault sync not available on Windows", Colors.YELLOW)
        print_colored("💡 Use WSL for vault synchronization features", Colors.BLUE)
        return
    
    print_colored("🔒 Synchronizing events to encrypted vault...", Colors.HEADER)
    success = run_script('scripts/gitswhy_vaultsync.sh', ['sync'])
    if success:
        print_colored("✅ Vault synchronization completed!", Colors.GREEN)
    else:
        print_colored("❌ Vault synchronization failed!", Colors.RED)
        raise click.ClickException("Vault synchronization failed")

@cli.command()
@click.option('--format', type=click.Choice(['json', 'summary', 'events']), 
              default='summary', help='Output format')
@click.option('--decrypt', is_flag=True, help='Decrypt and display vault contents')
@click.pass_context
def showvault(ctx: click.Context, format: str, decrypt: bool) -> None:
    """Display information about the encrypted vault."""
    print_colored("📊 Displaying vault information...", Colors.HEADER)
    if decrypt:
        success = run_script('scripts/gitswhy_vaultsync.sh', ['retrieve', format])
        if not success:
            print_colored("❌ Failed to decrypt vault contents!", Colors.RED)
            raise click.ClickException("Vault decryption failed")
    else:
        success = run_script('scripts/gitswhy_vaultsync.sh', ['status'])
        if not success:
            print_colored("❌ Failed to retrieve vault status!", Colors.RED)

@cli.command()
def fractal():
    """Basic open-source fractal context splitting: groups log events into domains."""
    import os
    from datetime import datetime
    config_path = 'config/gitswhy_config.yaml'
    log_path = os.path.expanduser('~/.gitswhy/events.log')
    domains = {'dev': ['git', 'code'], 'ops': ['system', 'flush']}  # Default domains

    try:
        # Attempt to read domains from config (simple parsing without external libs)
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                config_content = f.read()
            # Basic parsing: find 'fractal:' section and extract domains
            if 'fractal:' in config_content:
                fractal_section = config_content.split('fractal:')[1].split('#')[0]
                if 'domains:' in fractal_section:
                    domains_str = fractal_section.split('domains:')[1].strip()
                    domains = {}
                    for line in domains_str.split('\n'):
                        if ':' in line:
                            key, values = line.split(':', 1)
                            key = key.strip()
                            vals = [v.strip() for v in values.split(',') if v.strip()]
                            domains[key] = vals
        else:
            click.echo("[Warning] Config file not found; using default domains.")

        if not os.path.exists(log_path):
            raise FileNotFoundError(f"Events log not found at {log_path}.")

        with open(log_path, 'r') as f:
            lines = f.readlines()

        split_logs = {domain: [] for domain in domains}

        for line in lines:
            assigned = False
            for domain, keywords in domains.items():
                if any(kw.lower() in line.lower() for kw in keywords):
                    split_logs[domain].append(line)
                    assigned = True
                    break
            if not assigned:
                if 'other' not in split_logs:
                    split_logs['other'] = []
                split_logs['other'].append(line)

        for domain, content in split_logs.items():
            sub_log = os.path.expanduser(f'~/.gitswhy/events_{domain}.log')
            with open(sub_log, 'w') as f:
                f.writelines(content)
            click.echo(f"[ReflexCore] Split {len(content)} events to {sub_log}")

        click.echo("[ReflexCore] Fractal splitting completed successfully.")

    except FileNotFoundError as e:
        click.echo(f"[Error] Fractal splitting failed: {str(e)}")
    except Exception as e:
        click.echo(f"[Error] Unexpected error during fractal splitting: {str(e)}")

@cli.command()
def emotion():
    """Basic open-source emotion state mapping: analyzes event log intervals."""
    import os
    from datetime import datetime

    log_path = os.path.expanduser('~/.gitswhy/events.log')
    vault_path = os.path.expanduser('~/.gitswhy/vault.json')

    try:
        if not os.path.exists(log_path):
            click.echo(f"[Error] Events log not found at {log_path}.")
            return

        # Parse timestamps from log lines
        times = []
        with open(log_path, 'r') as f:
            for line in f:
                # Try to extract a timestamp (assume format: YYYY-MM-DD HH:MM:SS)
                parts = line.split()
                if len(parts) >= 2:
                    try:
                        t = datetime.strptime(f"{parts[0]} {parts[1]}", "%Y-%m-%d %H:%M:%S")
                        times.append(t)
                    except Exception:
                        continue

        if len(times) < 2:
            click.echo("[ReflexCore] Not enough events to analyze emotion states.")
            return

        # Analyze intervals and map to states
        states = []
        for i in range(1, len(times)):
            interval = (times[i] - times[i-1]).total_seconds()
            if interval > 2.0:
                state = f"fatigued (interval: {interval:.1f}s)"
            elif interval > 1.0:
                state = f"hesitant (interval: {interval:.1f}s)"
            else:
                state = f"focused (interval: {interval:.1f}s)"
            states.append(state)

        # Append states to vault (as plain text for now)
        with open(vault_path, 'a') as f:
            for state in states:
                f.write(f"Detected state: {state}\n")

        click.echo("[ReflexCore] Emotion states mapped and appended to vault.")
        click.echo(f"[ReflexCore] {len(states)} states written to {vault_path}")

    except Exception as e:
        click.echo(f"[Error] Unexpected error during emotion mapping: {str(e)}")

@cli.command()
@click.pass_context
def status(ctx: click.Context) -> None:
    print_colored("📊 Gitswhy ReflexCore System Status", Colors.HEADER)
    print_colored("=" * 50, Colors.BLUE)
    config_exists = check_config_exists()
    print_colored(f"Configuration: {'✅ Found' if config_exists else '❌ Missing'}", 
                  Colors.GREEN if config_exists else Colors.RED)
    scripts = ['init', 'overclock', 'flush', 'clean', 'mirror', 'syncvault']
    print_colored("\n📜 Script Status:", Colors.BLUE)
    for script in scripts:
        status_info = get_script_status(script)
        status_icon = "✅" if status_info['executable'] else "❌"
        print_colored(f"  {script:12} {status_icon} {'Executable' if status_info['executable'] else 'Not found'}", 
                      Colors.GREEN if status_info['executable'] else Colors.RED)
    vault_path = Path.home() / ".gitswhy" / "vault.json"
    vault_exists = vault_path.exists()
    print_colored(f"\n🔒 Vault Status: {'✅ Found' if vault_exists else '❌ Not created'}", 
                  Colors.GREEN if vault_exists else Colors.YELLOW)
    if vault_exists and ctx.obj['verbose']:
        vault_size = vault_path.stat().st_size
        print_colored(f"   Vault size: {vault_size} bytes", Colors.CYAN)

@cli.command()
@click.option('--service', help='Stop specific service only')
@click.pass_context  
def stop(ctx: click.Context, service: Optional[str]) -> None:
    print_colored("⏹️  Stopping ReflexCore services...", Colors.HEADER)
    success = run_script('scripts/gitswhy_initiate.sh', ['stop'])
    if success:
        print_colored("✅ ReflexCore services stopped successfully!", Colors.GREEN)
    else:
        print_colored("❌ Failed to stop some services!", Colors.RED)

@cli.command()
@click.pass_context
def restart(ctx: click.Context) -> None:
    print_colored("🔄 Restarting ReflexCore services...", Colors.HEADER)
    success = run_script('scripts/gitswhy_initiate.sh', ['restart'])
    if success:
        print_colored("✅ ReflexCore services restarted successfully!", Colors.GREEN)
    else:
        print_colored("❌ Failed to restart services!", Colors.RED)
        raise click.ClickException("Service restart failed")

@cli.command()
def troubleshooting():
    """Show troubleshooting tips and test instructions."""
    click.echo("\nTroubleshooting & Test Guide:")
    click.echo("- If a command fails, check logs in ~/.gitswhy/ or /root/.gitswhy/")
    click.echo("- Run 'python3 testall.py' for Python feature tests.")
    click.echo("- Run 'sudo ./test_all.sh' for full system tests.")
    click.echo("- Ensure all dependencies are installed: pip install click cryptography pyyaml, sudo apt install bc dd")
    click.echo("- For more help, see the README or docs/INSTALL.md.")

def handle_cli_error(e: Exception) -> None:
    if isinstance(e, click.ClickException):
        raise
    elif isinstance(e, subprocess.CalledProcessError):
        print_colored(f"❌ Command execution failed: {e}", Colors.RED)
        sys.exit(1)
    elif isinstance(e, FileNotFoundError):
        print_colored(f"❌ Required file not found: {e}", Colors.RED)
        sys.exit(1)
    else:
        print_colored(f"❌ Unexpected error: {e}", Colors.RED)
        sys.exit(1)

if __name__ == '__main__':
    try:
        cli()
    except Exception as e:
        handle_cli_error(e) 