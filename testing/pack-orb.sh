#!/bin/bash

set -euo pipefail

echo "===================================="
echo "Testing Orb Packing"
echo "===================================="

# Check if CircleCI CLI is installed
if ! command -v circleci &> /dev/null; then
    echo "ERROR: CircleCI CLI not found. Please install it first:"
    echo "curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | bash"
    exit 1
fi

# Check if src directory exists
if [ ! -d "src" ]; then
    echo "ERROR: src directory not found. Make sure you're running this from the orb root directory."
    exit 1
fi

# Create temporary directory for packed orb
temp_dir=$(mktemp -d)
packed_orb="$temp_dir/packed-orb.yml"

echo "Packing orb from src/ directory..."

# Pack the orb
if circleci orb pack src/ > "$packed_orb"; then
    echo "SUCCESS: Orb packed successfully!"
    echo "Packed orb saved to: $packed_orb"
    echo ""
    echo "Orb size: $(wc -l < "$packed_orb") lines"
    
    # Show first few lines as preview
    echo ""
    echo "Preview (first 10 lines):"
    echo "---"
    head -10 "$packed_orb"
    echo "---"
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo ""
    echo "Orb packing test completed successfully."
    exit 0
else
    echo "ERROR: Failed to pack orb. Check the error messages above."
    echo ""
    echo "Common issues:"
    echo "- YAML syntax errors in orb files"
    echo "- Missing required files or directories"
    echo "- Invalid orb structure"
    
    # Clean up
    rm -rf "$temp_dir"
    exit 1
fi 