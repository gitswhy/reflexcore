# Contributing to ReflexCore

![ReflexCore Logo](../assets/logo.png)

**ReflexCore v1.0.0** - Contributing guidelines for the cognition-native DevSecOps operating system.

Thank you for your interest in contributing to ReflexCore! We welcome all contributions—code, documentation, bug reports, and feature requests.

---

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style & Standards](#code-style--standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Communication](#communication)
- [Good First Issues](#good-first-issues)

---

## 🚀 Getting Started

### **Quick Start for Contributors**

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/reflexcore.git
   cd reflexcore
   ```

2. **Set up upstream remote**
   ```bash
   git remote add upstream https://github.com/gitswhy/reflexcore.git
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Install development dependencies**
   ```bash
   pip install -r requirements.txt
   chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py
   ```

5. **Test your setup**
   ```bash
   python3 -m pytest testall.py -v
   ```

---

## 🔧 Development Setup

### **Prerequisites**

- **Python 3.7+** with pip
- **Git** for version control
- **Bash 4.0+** for shell scripts
- **Linux/macOS** development environment
- **sudo privileges** (for system tests)

### **Development Environment**

```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/reflexcore.git
cd reflexcore

# Install dependencies
pip install -r requirements.txt

# Make scripts executable
chmod +x scripts/*.sh modules/*.sh gitswhy_vault_manager.py cli/gitswhy_cli.py

# Initialize ReflexCore
python3 cli/gitswhy_cli.py init

# Run tests to verify setup
python3 -m pytest testall.py -v
```

### **IDE Setup**

**VS Code (Recommended)**
```json
{
    "python.defaultInterpreterPath": "./venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black"
}
```

**PyCharm**
- Set project interpreter to virtual environment
- Enable PEP 8 inspection
- Configure shell script execution

---

## 📝 Code Style & Standards

### **Python Code**

- **Style Guide**: Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- **Formatting**: Use `black` for code formatting
- **Linting**: Use `flake8` for linting
- **Type Hints**: Use type hints for function parameters and return values
- **Docstrings**: Use Google-style docstrings

**Example:**
```python
#!/usr/bin/env python3
"""
Module description.

This module provides functionality for...
"""

from typing import Optional, Dict, Any
import click


def process_data(data: Dict[str, Any], config: Optional[str] = None) -> bool:
    """Process the given data with optional configuration.
    
    Args:
        data: The data to process
        config: Optional configuration file path
        
    Returns:
        True if processing was successful, False otherwise
        
    Raises:
        ValueError: If data is invalid
    """
    if not data:
        raise ValueError("Data cannot be empty")
    
    # Implementation here
    return True
```

### **Bash Scripts**

- **Linting**: Use [ShellCheck](https://www.shellcheck.net/) for all scripts
- **Style**: Follow POSIX-compliant syntax
- **Shebang**: Always use `#!/bin/bash`
- **Error Handling**: Use `set -euo pipefail`
- **Comments**: Document complex logic

**Example:**
```bash
#!/bin/bash

#==============================================================================
# Script Name: example_script.sh
# Description: Brief description of what this script does
# Author: Your Name
# Version: 1.0.0
#==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SCRIPT_NAME="ExampleScript"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Main function
main() {
    echo -e "${GREEN}[INFO]${NC} Starting example script..."
    
    # Your implementation here
    
    echo -e "${GREEN}[INFO]${NC} Example script completed successfully"
}

# Run main function
main "$@"
```

### **YAML Configuration**

- **Indentation**: Use 2 spaces
- **Comments**: Add descriptive comments
- **Structure**: Group related settings together
- **Validation**: Ensure valid YAML syntax

**Example:**
```yaml
# Feature toggles
features:
  vault_sync_enabled: true
  auto_optimization: true
  system_monitoring: true

# Performance settings
performance:
  swappiness: 10
  vfs_cache_pressure: 50
  max_cpu_temp: 85
```

### **Commit Messages**

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

**Examples:**
```
feat(cli): add new status command
fix(core): resolve hesitation detection issue
docs(readme): update installation instructions
test(vault): add comprehensive vault tests
```

---

## 🧪 Testing Guidelines

### **Running Tests**

```bash
# Python tests
python3 -m pytest testall.py -v

# System tests (requires sudo)
sudo ./test_all.sh

# Individual test files
python3 -m pytest test_decrypt.py -v

# With coverage
python3 -m pytest testall.py --cov=. --cov-report=html
```

### **Writing Tests**

**Python Tests (pytest)**
```python
import pytest
import tempfile
import os


@pytest.fixture
def temp_file():
    """Create temporary file for testing."""
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        f.write('{"test": "data"}')
        temp_file = f.name
    
    yield temp_file
    
    # Cleanup
    if os.path.exists(temp_file):
        os.unlink(temp_file)


def test_example_function(temp_file):
    """Test example function with temporary file."""
    # Arrange
    expected = {"test": "data"}
    
    # Act
    result = process_file(temp_file)
    
    # Assert
    assert result == expected
```

**Bash Tests**
```bash
#!/bin/bash

# Test script for example_script.sh

set -euo pipefail

# Test setup
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

# Test cases
test_basic_functionality() {
    echo "Testing basic functionality..."
    # Your test implementation
    echo "✓ Basic functionality test passed"
}

test_error_handling() {
    echo "Testing error handling..."
    # Your test implementation
    echo "✓ Error handling test passed"
}

# Run tests
test_basic_functionality
test_error_handling

echo "All tests passed!"
```

### **Test Requirements**

- **Coverage**: Aim for 80%+ code coverage
- **Unit Tests**: Test individual functions and methods
- **Integration Tests**: Test component interactions
- **System Tests**: Test full system functionality
- **Edge Cases**: Test error conditions and edge cases

---

## 🔄 Pull Request Process

### **Before Submitting**

1. **Update your branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all tests**
   ```bash
   python3 -m pytest testall.py -v
   sudo ./test_all.sh
   ```

3. **Check code style**
   ```bash
   # Python
   black --check .
   flake8 .
   
   # Bash
   shellcheck scripts/*.sh modules/*.sh
   ```

4. **Update documentation**
   - Update README.md if needed
   - Add docstrings for new functions
   - Update configuration examples

### **Creating the PR**

1. **Push your changes**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**
   - Go to GitHub and create PR
   - Use the PR template
   - Reference related issues
   - Add descriptive title and description

3. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Test addition
   - [ ] Other (please describe)

   ## Testing
   - [ ] All tests pass
   - [ ] New tests added
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No breaking changes
   ```

### **Review Process**

- **Automated Checks**: CI/CD pipeline runs tests and linting
- **Code Review**: Maintainers review within 24 hours
- **Feedback**: Address review comments promptly
- **Merge**: PR merged after approval and CI passing

---

## 🐛 Issue Reporting

### **Bug Reports**

Use the bug report template:

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 20.04]
- Python: [e.g., 3.8.5]
- ReflexCore: [e.g., v1.0.0]

## Additional Information
Logs, screenshots, etc.
```

### **Feature Requests**

Use the feature request template:

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why this feature is needed

## Proposed Solution
How you think it should work

## Alternatives Considered
Other approaches you considered

## Additional Information
Any other relevant details
```

---

## 💬 Communication

### **Channels**

- **GitHub Issues**: Bug reports, feature requests, questions
- **GitHub Discussions**: General discussions, ideas
- **Discord**: Real-time help, community chat
- **Email**: Sensitive matters (contact maintainers)

### **Discord Community**

Join our [Discord server](https://discord.com/invite/NuevNNzQwm) for:
- Real-time help and support
- Community discussions
- Development coordination
- Announcements and updates

### **Code of Conduct**

We follow a [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming and inclusive community. Please read and follow these guidelines.

---

## 🎯 Good First Issues

### **For New Contributors**

Look for issues labeled:
- `good first issue`
- `help wanted`
- `documentation`
- `bug`

### **Suggested First Contributions**

1. **Documentation**
   - Fix typos in README.md
   - Add examples to INSTALL.md
   - Improve inline comments

2. **Testing**
   - Add unit tests for existing functions
   - Improve test coverage
   - Add edge case tests

3. **Code Quality**
   - Fix ShellCheck warnings
   - Improve error handling
   - Add type hints

4. **Features**
   - Add new CLI commands
   - Improve configuration options
   - Add platform support

### **Getting Help**

- Comment on issues to ask questions
- Join Discord for real-time help
- Check existing documentation
- Look at similar PRs for examples

---

## 📋 Contributor Checklist

Before submitting your contribution:

- [ ] Code follows style guidelines
- [ ] Tests are written and passing
- [ ] Documentation is updated
- [ ] No breaking changes introduced
- [ ] Commit messages follow conventions
- [ ] PR description is clear and complete
- [ ] Related issues are referenced
- [ ] Self-review completed

---

## 🏆 Recognition

Contributors are recognized through:
- **GitHub Contributors** page
- **Release notes** for significant contributions
- **Community shoutouts** on Discord
- **Contributor badges** in documentation

---

## 📞 Getting Help

- **Documentation**: Check [README.md](../README.md) and [INSTALL.md](INSTALL.md)
- **Issues**: Search existing issues before creating new ones
- **Discord**: Join for real-time help
- **Maintainers**: Contact for sensitive matters

---

Thank you for helping make ReflexCore better! 🚀

**Ready to contribute?** Start with a [good first issue](https://github.com/gitswhy/reflexcore/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) or join our [Discord community](https://discord.com/invite/NuevNNzQwm)!

---

*ReflexCore v1.0.0 - Making development smarter, one keystroke at a time.* 