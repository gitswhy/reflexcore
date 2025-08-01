#!/bin/bash

# Make all shell scripts executable
echo "Making all shell scripts executable..."

# Make scripts in scripts/ directory executable
chmod +x scripts/*.sh

# Make scripts in modules/ directory executable
chmod +x modules/*.sh

# Make test scripts executable
chmod +x test_*.sh

echo "✅ All shell scripts are now executable!"
echo ""
echo "You can now run:"
echo "  python3 cli/gitswhy_cli.py mirror --timeout 60"
echo "  bash modules/gitswhy_coremirror.sh status"
echo "  bash test_coremirror.sh" 