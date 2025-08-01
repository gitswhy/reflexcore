#!/usr/bin/env python3
"""
Gitswhy Vault Manager
- Encrypts and decrypts vault files using Fernet symmetric encryption
- Supports store/retrieve operations
- Reads config for password/key
- Production ready: robust error handling, CLI, and logging
"""
import argparse
import os
import sys
import json
import base64
import yaml
from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend
from datetime import datetime

# =====================
# Utility Functions
# =====================
def load_config(config_path):
    if not os.path.isfile(config_path):
        raise FileNotFoundError(f"Config file not found: {config_path}")
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def get_password(config):
    # Priority: ENV > config > fallback
    pw = os.environ.get('GITSWHY_VAULT_PASSWORD')
    if pw:
        return pw
    # Try config
    vault_cfg = config.get('vault', {})
    pw = vault_cfg.get('vault_password')
    if pw:
        return pw
    # Fallback
    return 'gitswhy_default_vault_password_2025'

def get_iterations(config):
    vault_cfg = config.get('vault', {})
    return int(vault_cfg.get('vault_key_iterations', 100000))

def derive_key(password, salt, iterations=100000):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=iterations,
        backend=default_backend()
    )
    return base64.urlsafe_b64encode(kdf.derive(password.encode()))

def encrypt_data(data, password, iterations=100000):
    salt = os.urandom(16)
    key = derive_key(password, salt, iterations)
    f = Fernet(key)
    token = f.encrypt(data.encode())
    return base64.b64encode(salt).decode() + ':' + token.decode()

def decrypt_data(enc, password, iterations=100000):
    try:
        salt_b64, token = enc.split(':', 1)
        salt = base64.b64decode(salt_b64.encode())
        key = derive_key(password, salt, iterations)
        f = Fernet(key)
        return f.decrypt(token.encode()).decode()
    except (InvalidToken, ValueError, Exception) as e:
        raise RuntimeError(f"Decryption failed: {e}")

def read_json_file(path):
    with open(path, 'r') as f:
        return json.load(f)

def write_json_file(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

def read_text_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_text_file(path, data):
    with open(path, 'w') as f:
        f.write(data)

def analyze_vault(vault_file, config_path, password=None, keyword=None, start_time=None, end_time=None):
    """
    Automatically decrypts the vault (if needed) and performs analytics.
    """
    try:
        import json
        # Load config and password if not provided
        if not password:
            if os.path.exists(config_path):
                import yaml
                with open(config_path, 'r') as f:
                    config = yaml.safe_load(f)
                vault_cfg = config.get('vault', {})
                password = vault_cfg.get('vault_password', 'gitswhy_default_vault_password_2025')
            else:
                password = 'gitswhy_default_vault_password_2025'
        # Read vault file
        if not os.path.exists(vault_file):
            print(f"[ERROR] Vault file not found: {vault_file}")
            return {'count': 0, 'events': []}
        with open(vault_file, 'r') as f:
            enc = f.read()
        # Try to parse as JSON first
        try:
            data = json.loads(enc)
        except Exception:
            # Try to decrypt using Fernet
            try:
                from cryptography.fernet import Fernet, InvalidToken
                from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
                from cryptography.hazmat.primitives import hashes
                from cryptography.hazmat.backends import default_backend
                import base64
                # Extract salt and token
                salt_b64, token = enc.split(':', 1)
                salt = base64.b64decode(salt_b64.encode())
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA256(),
                    length=32,
                    salt=salt,
                    iterations=100000,
                    backend=default_backend()
                )
                key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
                fernet = Fernet(key)
                dec = fernet.decrypt(token.encode()).decode()
                data = json.loads(dec)
            except Exception as e:
                print(f"[ERROR] Failed to decrypt or parse vault: {e}")
                return {'count': 0, 'events': []}
        events = data if isinstance(data, list) else data.get('data', [])
        results = []
        for event in events:
            match = True
            if keyword and keyword.lower() not in str(event).lower():
                match = False
            if start_time:
                try:
                    start_dt = datetime.strptime(start_time, '%Y-%m-%d %H:%M:%S')
                    event_dt = datetime.strptime(event.get('timestamp', ''), '%Y-%m-%d %H:%M:%S')
                    if event_dt < start_dt:
                        match = False
                except Exception:
                    print("[WARN] Invalid start_time or event timestamp format.")
                    match = False
            if end_time:
                try:
                    end_dt = datetime.strptime(end_time, '%Y-%m-%d %H:%M:%S')
                    event_dt = datetime.strptime(event.get('timestamp', ''), '%Y-%m-%d %H:%M:%S')
                    if event_dt > end_dt:
                        match = False
                except Exception:
                    print("[WARN] Invalid end_time or event timestamp format.")
                    match = False
            if match:
                results.append(event)
        count = len(results)
        print(f"Analytics Results: {count} events found.")
        if results:
            print(json.dumps(results, indent=2))
        return {'count': count, 'events': results}
    except Exception as e:
        print(f"[ERROR] Analytics failed: {str(e)}")
        return {'count': 0, 'events': []}

def analyze_vault_builtin(vault_file, keyword=None, start_time=None, end_time=None):
    """
    Analyze plain JSON vault files (no encryption).
    """
    try:
        if not os.path.exists(vault_file):
            print(f"[ERROR] Vault file not found: {vault_file}")
            return []
        with open(vault_file, 'r') as f:
            data = json.load(f)
        events = data if isinstance(data, list) else data.get('data', [])
        results = []
        count = 0
        for event in events:
            match = True
            if keyword and keyword.lower() not in str(event).lower():
                match = False
            if start_time:
                try:
                    start_dt = datetime.strptime(start_time, '%Y-%m-%d %H:%M:%S')
                    event_dt = datetime.strptime(event.get('timestamp', ''), '%Y-%m-%d %H:%M:%S')
                    if event_dt < start_dt:
                        match = False
                except Exception:
                    print("[WARN] Invalid start_time or event timestamp format.")
                    match = False
            if end_time:
                try:
                    end_dt = datetime.strptime(end_time, '%Y-%m-%d %H:%M:%S')
                    event_dt = datetime.strptime(event.get('timestamp', ''), '%Y-%m-%d %H:%M:%S')
                    if event_dt > end_dt:
                        match = False
                except Exception:
                    print("[WARN] Invalid end_time or event timestamp format.")
                    match = False
            if match:
                results.append(event)
                count += 1
        print(f"Found {count} matching events.")
        if results:
            print(json.dumps(results, indent=2))
        return results
    except Exception as e:
        print(f"[Error] Analytics failed: {str(e)}")
        return []

def main():
    parser = argparse.ArgumentParser(description='Gitswhy Vault Manager')
    parser.add_argument('--version', action='version', version='Gitswhy Vault Manager v1.0.0')
    parser.add_argument('--operation', choices=['store', 'retrieve', 'view', 'analyze', 'analyze_builtin'], default='store')
    parser.add_argument('--input-file', help='Input file (for store)')
    parser.add_argument('--vault-file', required=True, help='Vault file path')
    parser.add_argument('--config', help='YAML config file (required for encrypted operations)')
    parser.add_argument('--output-format', default='json', choices=['json', 'summary'], help='Output format for retrieve')
    parser.add_argument('--keyword', help='Keyword to search in events (for analyze)')
    parser.add_argument('--start_time', help='Start timestamp for range (YYYY-MM-DD HH:MM:SS)')
    parser.add_argument('--end_time', help='End timestamp for range (YYYY-MM-DD HH:MM:SS)')
    args = parser.parse_args()

    # Only require config for encrypted operations
    encrypted_ops = ['store', 'retrieve', 'view', 'analyze']
    if args.operation in encrypted_ops and not args.config:
        print("[ERROR] --config is required for this operation.", file=sys.stderr)
        sys.exit(1)

    if args.operation in encrypted_ops:
        try:
            config = load_config(args.config)
            password = get_password(config)
            iterations = get_iterations(config)
        except Exception as e:
            print(f"[ERROR] Failed to load config or password: {e}", file=sys.stderr)
            sys.exit(1)

    if args.operation == 'store':
        if not args.input_file or not os.path.isfile(args.input_file):
            print(f"[ERROR] Input file not found: {args.input_file}", file=sys.stderr)
            sys.exit(1)
        try:
            try:
                data = read_json_file(args.input_file)
            except Exception:
                data = read_text_file(args.input_file)
            if not isinstance(data, str):
                data = json.dumps(data)
            enc = encrypt_data(data, password, iterations)
            write_text_file(args.vault_file, enc)
            print(f"[INFO] Vault file created: {args.vault_file}")
        except Exception as e:
            print(f"[ERROR] Failed to store vault: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.operation == 'retrieve':
        if not os.path.isfile(args.vault_file):
            print(f"[ERROR] Vault file not found: {args.vault_file}", file=sys.stderr)
            sys.exit(1)
        try:
            enc = read_text_file(args.vault_file)
            dec = decrypt_data(enc, password, iterations)
            if args.output_format == 'json':
                print(dec)
            elif args.output_format == 'summary':
                try:
                    data = json.loads(dec)
                    print(f"[SUMMARY] Vault contains {len(data) if isinstance(data, list) else 1} records.")
                except Exception:
                    print("[SUMMARY] Vault decrypted (non-JSON content).")
        except Exception as e:
            print(f"[ERROR] Failed to retrieve vault: {e}", file=sys.stderr)
            sys.exit(1)
    elif args.operation == 'analyze':
        analyze_vault(
            args.vault_file,
            config_path=args.config,
            keyword=args.keyword,
            start_time=args.start_time,
            end_time=args.end_time
        )
    elif args.operation == 'analyze_builtin':
        analyze_vault_builtin(
            args.vault_file,
            keyword=args.keyword,
            start_time=args.start_time,
            end_time=args.end_time
        )
    else:
        print(f"[ERROR] Unknown operation: {args.operation}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main() 