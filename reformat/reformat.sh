#!/bin/bash
set -e

echo ""
echo "=========================================="
echo "Running Black (code formatter)..."
echo "=========================================="
black --line-length 80 --target-version py311 tests/

echo ""
echo "=========================================="
echo "Running docformatter (docstring formatter)..."
echo "=========================================="
docformatter --wrap-summaries 79 --wrap-descriptions 79 --in-place --recursive tests/

echo ""
echo "=========================================="
echo "Running isort (import sorter)..."
echo "=========================================="
isort --profile black tests/

echo ""
echo "=========================================="
echo "Formatting complete!"
echo "=========================================="
