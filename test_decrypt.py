import os
import base64
import pytest
from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend

password = "gitswhy_default_vault_password_2025"
iterations = 100000

def try_decrypt_vault(vault_path):
    if not os.path.exists(vault_path):
        return None, f"Vault file not found: {vault_path}"
    with open(vault_path, "r") as f:
        enc = f.read().strip()
    try:
        salt_b64, token = enc.split(':', 1)
        salt = base64.b64decode(salt_b64.encode())
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=iterations,
            backend=default_backend()
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        fernet = Fernet(key)
        dec = fernet.decrypt(token.encode()).decode()
        return dec, None
    except Exception as e:
        return None, f"Decryption failed: {e}"

def test_decrypt_vault():
    vault_path = os.path.expanduser("~/.gitswhy/vault.json")
    dec, err = try_decrypt_vault(vault_path)
    if err and "Vault file not found" in err:
        pytest.skip(err)
    elif err:
        pytest.fail(err)
    else:
        print("Decryption successful! Vault contents:")
        print(dec) 