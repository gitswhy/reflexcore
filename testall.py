import os
import subprocess
import json

def run(cmd):
    print(f"\n$ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)
    return result

# Paths
config = "config/gitswhy_config.yaml"
vault_file = os.path.expanduser("~/.gitswhy/vault.json")
test_data = os.path.expanduser("~/test_data.json")

# 1. Create test data
sample = [
    {"timestamp": "2025-07-23 10:01:00", "event": "hesitation", "details": "test"},
    {"timestamp": "2025-07-23 10:02:00", "event": "typing", "details": "ok"}
]
with open(test_data, "w") as f:
    json.dump(sample, f)
print(f"Test data written to {test_data}")

# 2. Store (encrypt) test data in vault
run(f"python3 gitswhy_vault_manager.py --config {config} --vault-file {vault_file} --operation store --input-file {test_data}")

# 3. Retrieve (decrypt) vault
run(f"python3 gitswhy_vault_manager.py --config {config} --vault-file {vault_file} --operation retrieve")

# 4. Analyze (encrypted vault)
run(f"python3 gitswhy_vault_manager.py --config {config} --vault-file {vault_file} --operation analyze --keyword hesitation")

# 5. Analyze_builtin (plain JSON)
run(f"python3 gitswhy_vault_manager.py --operation analyze_builtin --vault-file {test_data} --keyword hesitation --config {config}")

print("\nAll tests completed.") 