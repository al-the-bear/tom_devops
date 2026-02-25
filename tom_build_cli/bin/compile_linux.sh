#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SCRIPT_DIR/ubuntu"

echo "Compiling tom_build_tools binaries for Linux..."
echo "Project: $PROJECT_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get dependencies first
cd "$PROJECT_DIR"
dart pub get

# List of tools to compile
TOOLS=(
    "md_latex_converter"
    "md_pdf_converter"
    "mode_switcher"
    "reflection_generator"
    "tom_build_tools"
    "ws_analyzer"
    "ws_analyzer_all"
)

# Compile each tool
for tool in "${TOOLS[@]}"; do
    echo "Compiling $tool..."
    dart compile exe "$PROJECT_DIR/bin/$tool.dart" -o "$OUTPUT_DIR/$tool"
    chmod +x "$OUTPUT_DIR/$tool"
    echo "  ✓ $tool compiled"
done

echo ""
echo "All binaries compiled successfully to: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR"
