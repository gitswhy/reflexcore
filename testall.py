import os
import subprocess
import json
import pytest
import tempfile
import shutil

def run(cmd):
    """Helper function to run shell commands and return results"""
    print(f"\n$ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)
    return result

@pytest.fixture(scope="session")
def test_data_file():
    """Create test data file for vault operations"""
    sample = [
        {"timestamp": "2025-07-23 10:01:00", "event": "hesitation", "details": "test"},
        {"timestamp": "2025-07-23 10:02:00", "event": "typing", "details": "ok"}
    ]
    
    # Create temporary file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(sample, f)
        temp_file = f.name
    
    yield temp_file
    
    # Cleanup
    if os.path.exists(temp_file):
        os.unlink(temp_file)

@pytest.fixture(scope="session")
def vault_file():
    """Get vault file path"""
    return os.path.expanduser("~/.gitswhy/vault.json")

@pytest.fixture(scope="session")
def config_file():
    """Get config file path"""
    return "config/gitswhy_config.yaml"

def test_vault_store_operation(test_data_file, vault_file, config_file):
    """Test storing data in vault"""
    print(f"Testing vault store operation...")
    result = run(f"python3 gitswhy_vault_manager.py --config {config_file} --vault-file {vault_file} --operation store --input-file {test_data_file}")
    assert result.returncode == 0, f"Vault store operation failed: {result.stderr}"
    print("✓ Vault store operation completed successfully")

def test_vault_retrieve_operation(vault_file, config_file):
    """Test retrieving data from vault"""
    print(f"Testing vault retrieve operation...")
    result = run(f"python3 gitswhy_vault_manager.py --config {config_file} --vault-file {vault_file} --operation retrieve")
    assert result.returncode == 0, f"Vault retrieve operation failed: {result.stderr}"
    print("✓ Vault retrieve operation completed successfully")

def test_vault_analyze_operation(vault_file, config_file):
    """Test analyzing encrypted vault"""
    print(f"Testing vault analyze operation...")
    result = run(f"python3 gitswhy_vault_manager.py --config {config_file} --vault-file {vault_file} --operation analyze --keyword hesitation")
    assert result.returncode == 0, f"Vault analyze operation failed: {result.stderr}"
    print("✓ Vault analyze operation completed successfully")

def test_vault_analyze_builtin_operation(test_data_file, config_file):
    """Test analyzing plain JSON data"""
    print(f"Testing vault analyze_builtin operation...")
    result = run(f"python3 gitswhy_vault_manager.py --operation analyze_builtin --vault-file {test_data_file} --keyword hesitation --config {config_file}")
    assert result.returncode == 0, f"Vault analyze_builtin operation failed: {result.stderr}"
    print("✓ Vault analyze_builtin operation completed successfully")

def test_config_file_exists(config_file):
    """Test that config file exists"""
    assert os.path.exists(config_file), f"Config file not found: {config_file}"
    print(f"✓ Config file exists: {config_file}")

def test_vault_manager_exists():
    """Test that vault manager script exists"""
    vault_manager = "gitswhy_vault_manager.py"
    assert os.path.exists(vault_manager), f"Vault manager script not found: {vault_manager}"
    print(f"✓ Vault manager script exists: {vault_manager}")

if __name__ == "__main__":
    # Allow running as script for backward compatibility
    pytest.main([__file__, "-v"]) 