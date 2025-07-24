![ReflexCore Logo](../assets/logo.png)

# Contributing to ReflexCore

Thank you for your interest in contributing to ReflexCore! We welcome all contributions—code, documentation, bug reports, and feature requests.

---

## How to Contribute

1. **Fork the repository**
   - Click the "Fork" button on GitHub and clone your fork locally.
2. **Create a feature branch**
   - `git checkout -b feature/your-feature`
3. **Make your changes**
   - Write clear, well-documented code.
   - Add or update tests if applicable.
4. **Test locally**
   - Run `sudo ./test_all.sh` and ensure all tests pass.
5. **Commit and push**
   - `git add . && git commit -m "Describe your change" && git push origin feature/your-feature`
6. **Open a Pull Request (PR)**
   - Go to GitHub and open a PR against `main`.
   - Reference any related issues.

---

## Code Style
- **Python:** Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/). Use `black` or `flake8` for formatting.
- **Bash:** Use [ShellCheck](https://www.shellcheck.net/) for linting. Prefer POSIX-compliant syntax.
- **Commits:** Use clear, descriptive commit messages.

---

## Good First Issues
- Look for issues labeled `good first issue` or `help wanted`.
- If you’re new, comment on the issue to get guidance from maintainers.

---

## Pull Request Review
- PRs are reviewed within 24 hours.
- All tests and CI must pass before merging.
- You may be asked to make changes—please respond promptly.

---

## Contributor License Agreement (CLA)
- By submitting a PR, you agree to our simple [CLA](CLA.md).
- You’ll be prompted to sign on your first PR.

---

## Communication
- **Issues:** Use GitHub Issues for bugs, features, and questions.
- **Discord:** Join our community for real-time help (link in README).
- **Email:** For sensitive matters, contact the maintainers directly.

---

## Testing & Troubleshooting
- Run 'python3 testall.py' for Python feature tests.
- Run 'sudo ./test_all.sh' for full system tests.
- Use --version to check script/CLI versions.
- For analytics, --config is only required for encrypted vault operations.
- See the README for troubleshooting tips before submitting a PR.

---

Thank you for helping make ReflexCore better! 