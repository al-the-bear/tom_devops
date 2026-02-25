#!/bin/bash
# Tom CLI Replay Test Runner
# Runs all Tom replay tests AND D4rt/DCli tests for compatibility

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
TOTAL=0

# Create results directory
mkdir -p test/results

echo "========================================"
echo "Tom CLI Replay Test Runner"
echo "========================================"
echo ""

# Run Tom-specific tests
echo "Running Tom-specific tests..."
for test_file in test/replay/*.tom; do
    if [ -f "$test_file" ]; then
        test_name=$(basename "$test_file")
        TOTAL=$((TOTAL + 1))
        echo -n "  Running $test_name... "
        
        result_file="test/results/${test_name%.tom}.result.txt"
        if tom -run-replay "$test_file" -test -output="$result_file" 2>&1 | grep -q "PASSED"; then
            echo -e "${GREEN}PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAILED${NC}"
            FAILED=$((FAILED + 1))
            echo "    See: $result_file"
        fi
    fi
done
echo ""

# Run D4rt tests with Tom (compatibility)
D4RT_TEST_DIR="/Users/alexiskyaw/Desktop/Code/tom2/dartscript/tom_dartscript_bridges/test/replay"
if [ -d "$D4RT_TEST_DIR" ]; then
    echo "Running D4rt tests with Tom (compatibility)..."
    for test_file in "$D4RT_TEST_DIR"/*.d4rt; do
        if [ -f "$test_file" ]; then
            test_name=$(basename "$test_file")
            TOTAL=$((TOTAL + 1))
            echo -n "  Running $test_name (tom)... "
            
            result_file="test/results/d4rt_compat_${test_name%.d4rt}.result.txt"
            if tom -run-replay "$test_file" -test -output="$result_file" 2>&1 | grep -q "PASSED"; then
                echo -e "${GREEN}PASSED${NC}"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}FAILED${NC}"
                FAILED=$((FAILED + 1))
                echo "    See: $result_file"
            fi
        fi
    done
    echo ""
fi

# Run DCli tests with Tom (compatibility)
DCLI_TEST_DIR="/Users/alexiskyaw/Desktop/Code/tom2/xternal/tom_module_d4rt/tom_d4rt_dcli/test/replay"
if [ -d "$DCLI_TEST_DIR" ]; then
    echo "Running DCli tests with Tom (compatibility)..."
    for test_file in "$DCLI_TEST_DIR"/*.dcli; do
        if [ -f "$test_file" ]; then
            test_name=$(basename "$test_file")
            TOTAL=$((TOTAL + 1))
            echo -n "  Running $test_name (tom)... "
            
            result_file="test/results/dcli_compat_${test_name%.dcli}.result.txt"
            if tom -run-replay "$test_file" -test -output="$result_file" 2>&1 | grep -q "PASSED"; then
                echo -e "${GREEN}PASSED${NC}"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}FAILED${NC}"
                FAILED=$((FAILED + 1))
                echo "    See: $result_file"
            fi
        fi
    done
    echo ""
fi

echo "========================================"
echo -e "Test Results: ${PASSED}/${TOTAL} passed"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${FAILED} test(s) failed${NC}"
    exit 1
fi
