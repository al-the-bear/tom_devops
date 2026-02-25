#!/bin/bash
# Generate All Bridges Script
# This script generates and verifies all D4rt bridges in tom_build

set -e

echo "================================"
echo "Tom Build D4rt Bridge Generator"
echo "================================"
echo ""

# Change to tom_build directory
cd "$(dirname "$0")"

# Parse command line arguments
GENERATE=false
VERIFY_ONLY=false
VERBOSE=false
SPECIFIC_MODULE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --generate|-g)
            GENERATE=true
            shift
            ;;
        --verify|-v)
            VERIFY_ONLY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --module|-m)
            SPECIFIC_MODULE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --generate, -g    Generate bridges for all modules"
            echo "  --verify, -v      Only verify existing bridges (no generation)"
            echo "  --verbose         Show detailed output"
            echo "  --module, -m NAME Generate only for specific module"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Modules: tom, dartscript"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# =============================================================================
# Generation Mode
# =============================================================================

if [[ "$GENERATE" == "true" ]]; then
    echo "Generating D4rt bridges..."
    echo ""
    
    if [[ -n "$SPECIFIC_MODULE" ]]; then
        # Generate for specific module only
        echo "Generating bridges for module: $SPECIFIC_MODULE"
        dart run tool/generate_bridge.dart --module="$SPECIFIC_MODULE" ${VERBOSE:+--verbose}
    else
        # Generate for all modules
        echo "=== Generating Tom CLI bridges ==="
        dart run tool/generate_tom_cli_bridges.dart
        echo ""
        
        echo "=== Generating DartScript bridges ==="
        dart run tool/generate_bridge.dart --module=dartscript ${VERBOSE:+--verbose}
        echo ""
        
        echo "=== Generating Analyzer bridges ==="
        dart run tool/generate_bridge.dart --module=analyzer ${VERBOSE:+--verbose}
        echo ""
        
        echo "=== Generating Tools bridges ==="
        dart run tool/generate_bridge.dart --module=tools ${VERBOSE:+--verbose}
        echo ""
        
        echo "=== Generating Scripting bridges ==="
        dart run tool/generate_bridge.dart --module=scripting ${VERBOSE:+--verbose}
        echo ""
        
        echo "=== Generating ReflectionGenerator bridges ==="
        dart run tool/generate_bridge.dart --module=reflection_generator ${VERBOSE:+--verbose}
        echo ""
        
        echo "=== Generating WsPrepper bridges ==="
        dart run tool/generate_bridge.dart --module=ws_prepper ${VERBOSE:+--verbose}
        echo ""
    fi
    
    echo ""
fi

# =============================================================================
# Verification Mode
# =============================================================================

echo "Scanning tom_build for bridge files..."
echo ""

# Find all *_bridge.dart files
bridges=$(find lib/src -name "*_bridge.dart" -type f | sort)

echo "Found bridges:"
echo "-------------"
for bridge in $bridges; do
    # Get the bridge class name from the file
    class_name=$(grep -o "class [A-Z][a-zA-Z]*Bridge" "$bridge" | head -1 | awk '{print $2}')
    
    # Count bridged classes (count BridgedClass( occurrences)
    count=$(grep -c "BridgedClass(" "$bridge" || echo "0")
    
    # Get the module name from the file path
    module=$(echo "$bridge" | sed 's|lib/src/||' | sed 's|/.*||')
    
    # Check if it's a generated file
    if [[ "$bridge" == *"_generated.dart" ]]; then
        gen_marker="[generated]"
    else
        gen_marker="[manual]"
    fi
    
    echo "  ✓ $class_name ($module) - $count bridged class definitions $gen_marker"
done

echo ""
echo "Verification:"
echo "------------"

# Check if all bridges are registered in tom_build_bridge.dart
echo "Checking tom_build_bridge.dart registrations..."
for bridge in $bridges; do
    # Skip generated files - they're included via the main bridge file
    if [[ "$bridge" == *"_generated.dart" ]]; then
        continue
    fi
    
    class_name=$(grep -o "class [A-Z][a-zA-Z]*Bridge" "$bridge" | head -1 | awk '{print $2}')
    if [[ -z "$class_name" ]]; then
        continue
    fi
    
    if grep -q "$class_name" lib/src/tom_build_bridge.dart; then
        echo "  ✓ $class_name registered in TomBuildBridge"
    else
        echo "  ✗ $class_name NOT registered in TomBuildBridge"
    fi
done

echo ""
echo "Checking dartscript.dart exports..."
for bridge in $bridges; do
    # Skip generated files
    if [[ "$bridge" == *"_generated.dart" ]]; then
        continue
    fi
    
    bridge_path=$(echo "$bridge" | sed 's|lib/||')
    if grep -q "$bridge_path" lib/dartscript.dart 2>/dev/null; then
        echo "  ✓ $bridge_path exported"
    else
        echo "  ✗ $bridge_path NOT exported (may need manual addition)"
    fi
done

echo ""
echo "Bridge Summary:"
echo "--------------"
total_bridges=$(echo "$bridges" | wc -l | tr -d ' ')
echo "Total bridge files: $total_bridges"

# Count total bridged classes from tom_build_bridge.dart
total_classes=$(grep -o "bridgedClassCount => [0-9]*" lib/src/tom_build_bridge.dart | grep -o "[0-9]*" || echo "?")
echo "Total bridged classes: $total_classes"

# Count manually written vs generated
manual_count=$(echo "$bridges" | grep -v "_generated.dart" | wc -l | tr -d ' ')
gen_count=$(echo "$bridges" | grep "_generated.dart" | wc -l | tr -d ' ')
echo "Manual bridges: $manual_count"
echo "Generated bridges: $gen_count"

echo ""
echo "Module Bridge List:"
echo "-------------------"
grep "moduleNames => \[" lib/src/tom_build_bridge.dart -A 15 | grep "'" | sed "s/[', ]//g" || echo "(not found)"

echo ""
echo "Done!"
