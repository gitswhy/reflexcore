![ReflexCore Logo](../assets/logo.png)

# ReflexCore Installation Guide

This guide will help you install and configure ReflexCore on Linux, WSL, or macOS.

---

## 1. Prerequisites
- **Python 3.7+** and `pip` (check with `python3 --version` and `pip --version`)
- **Bash** (default on Linux/macOS/WSL)
- **git**
- (Optional) `sudo` privileges for system-level optimizations

---

## 2. Clone the Repository
```bash
git clone https://github.com/gitswhy/reflexcore.git
cd reflexcore
```

---

## 3. Install Python Dependencies
```bash
pip install click cryptography pyyaml
```

---

## 4. Make Scripts Executable
```bash
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py
```

---

## 5. (Optional) Add to Shell Startup
Add ReflexCore to your `.bashrc` or `.zshrc` to auto-start background agents:
```bash
source /path/to/reflexcore/scripts/gitswhy_initiate.sh
```
Then restart your shell.

---

## 6. Initialize ReflexCore
```bash
python3 cli/gitswhy_cli.py init
```

---

## 7. Run the Test Suite (Recommended)
```bash
sudo ./test_all.sh
```
All tests should pass. If not, check logs in `~/.gitswhy/` or `/root/.gitswhy/`.

---

## 8. Usage Examples
- **Monitor keystrokes:**
  ```bash
  python3 cli/gitswhy_cli.py mirror
  ```
- **Flush system entropy:**
  ```bash
  sudo python3 cli/gitswhy_cli.py flush
  ```
- **Show vault summary:**
  ```bash
  python3 cli/gitswhy_cli.py showvault --decrypt --format summary
  ```

---

## Version Info
- All major scripts and CLI now support --version for quick version checks.

---

## Analytics Config Note
- For analytics, --config is only required for encrypted vault operations. For built-in analytics on plain JSON, --config is optional.

---

## Troubleshooting & Tests
- See the new Quick Troubleshooting and How to Run All Tests sections in the README for help and verification steps before launch.

---

## 9. Troubleshooting
- **Permission denied:** Ensure scripts are executable and run with `sudo` if needed.
- **Missing dependencies:** Re-run `pip install ...` as above.
- **Vault not created:** Run `python3 cli/gitswhy_cli.py syncvault` to create the vault.
- **Logs:** Check `~/.gitswhy/` or `/root/.gitswhy/` for logs and vault files.

---

## 10. Uninstall
Simply remove the ReflexCore directory and any lines from your shell startup files.

---

For advanced configuration, see `config/gitswhy_config.yaml` and the main [README.md](../README.md). 