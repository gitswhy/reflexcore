# ReflexCore: Open-Source Cognitive Shell for Gitswhy OS

![ReflexCore Logo](https://via.placeholder.com/150?text=ReflexCore) 

[![GitHub stars](https://img.shields.io/github/stars/gitswhy/reflexcore?style=social)](https://github.com/gitswhy/reflexcore/stargazers)
[![Apache License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/gitswhy/reflexcore/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/gitswhy/reflexcore)](https://github.com/gitswhy/reflexcore/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/gitswhy/reflexcore)](https://github.com/gitswhy/reflexcore/pulls)
[![CI Status](https://github.com/gitswhy/reflexcore/actions/workflows/reflexcore-ci.yml/badge.svg)](https://github.com/gitswhy/reflexcore/actions/workflows/reflexcore-ci.yml)

**Join our community on [Discord](https://discord.com/invite/NuevNNzQwm)!**

ReflexCore is the open-source foundation for Gitswhy OS—a cognition-native DevSecOps operating system. It provides a lightweight, background-running agent that enhances your shell with real-time monitoring, performance optimization, and secure event logging. Run it on Linux or macOS to detect hesitations, flush system entropy, auto-clean resources, and store intent data in encrypted vaults.

## Features
- **Bootstrapping**: Easy initialization of all modules in the background (`gitswhy_initiate.sh`).
- **Performance Overclocking**: Tunes system parameters for faster response (`gitswhy_gpuoverclock.sh`).
- **Entropy Flush**: Resets DNS, caches, and system sludge (`gitswhy_quantumflush.sh`).
- **Auto-Cleaning**: Kills zombies and clears temp files (`gitswhy_autoclean.sh`).
- **Core Monitoring**: Tracks keystrokes and detects cognitive drift (`gitswhy_coremirror.sh`).
- **Vault Management**: Aggregates and encrypts events (`gitswhy_vaultsync.sh` and `gitswhy_vault_manager.py`).
- **Unified CLI**: Manage everything with simple commands (`gitswhy_cli.py`).
- **Placeholders**: Basic stubs for fractal memory and emotion mapping—extend as needed.

## Quick Start
1. Clone the repo: `git clone https://github.com/gitswhy/reflexcore.git`
2. Install dependencies (if needed): `pip install click cryptography`
3. One-line install: Add `source /path/to/reflexcore/scripts/gitswhy_initiate.sh` to your `.bashrc` or `.zshrc`, then restart your shell.
4. Initialize: `python3 cli/gitswhy_cli.py init`
5. Test monitoring: Run `python3 cli/gitswhy_cli.py mirror` and type slowly—watch for hesitation alerts.
6. View vault: `python3 cli/gitswhy_cli.py showvault`

For full setup, see [docs/INSTALL.md](docs/INSTALL.md).

## Contribution Guide
We welcome contributions! Here's how to get started:
- **Fork the repo** and create a branch: `git checkout -b feature/new-module`
- **Make changes** and test locally.
- **Submit a PR**: Reference an issue if applicable. We review within 24 hours.
- **Good First Issues**: Look for labels like "good first issue" or "help wanted."
- **Code Style**: Follow PEP 8 for Python, ShellCheck for Bash.
- **CLA**: Sign our simple Contributor License Agreement on PR submission.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License Change Note
This project has switched from the MIT License to the Apache License 2.0 to provide better patent protection for contributors and users while remaining fully permissive. 

- **Why the Change?** Apache 2.0 includes explicit patent grants, protecting against patent litigation risks in an open-core model. This ensures the core remains free and open, while allowing for proprietary extensions (e.g., advanced AI features in future pro versions).
- **Impact on Users/Contributors**: Minimal—it's still permissive (you can use, modify, and distribute freely). Existing forks under MIT remain valid, but new contributions must follow Apache 2.0. No action is required unless you're relying on MIT-specific terms.
- **Questions?** Open an issue or check the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for details.

## Issue Templates
Use our templates for bug reports, feature requests, or questions—see [.github/ISSUE_TEMPLATE](.github/ISSUE_TEMPLATE).

Questions? Join our [Discord](https://discord.com/invite/NuevNNzQwm) or open an issue! 

## Quick Troubleshooting
- If a command fails, check logs in ~/.gitswhy/ or /root/.gitswhy/
- Ensure all dependencies are installed: pip install click cryptography pyyaml, sudo apt install bc dd
- If you see a config error, check config/gitswhy_config.yaml and ensure required fields are present.
- For analytics, --config is only required for encrypted vault operations.
- For more help, see docs/INSTALL.md or run the CLI with --help.

## How to Run All Tests
- Python feature tests: `python3 testall.py`
- Full system tests: `sudo ./test_all.sh`
- All tests should pass before public launch.

## Version Info
- All major scripts and CLI now support --version for quick version checks. 