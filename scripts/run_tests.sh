#!/bin/bash



set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_FAILED=0

run_test() {
    local test_name=$1
    echo -e "${YELLOW}Running ${test_name}...${NC}"
    if make $test_name; then
        echo -e "${GREEN}✓ ${test_name} passed${NC}"
    else
        echo -e "${RED}✗ ${test_name} failed${NC}"
        TEST_FAILED=1
    fi
    echo ""
}

echo "=========================================="
echo "    COMPREHENSIVE TEST SUITE"
echo "=========================================="
echo ""


run_test "format"


run_test "test_cppcheck"


run_test "build_debug"


run_test "test_units"


run_test "test_valgrind"


run_test "test_sanitizer"

# run_test "test_helgrind"

echo "=========================================="
if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}    ALL TESTS PASSED ✓${NC}"
    exit 0
else
    echo -e "${RED}    SOME TESTS FAILED ✗${NC}"
    exit 1
fi
echo "=========================================="