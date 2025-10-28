# ==============================================================================
# Project Configuration
# ==============================================================================
PROJECT_NAME := parser
BUILD_DIR := build
BIN_DIR := bin
TEST_DATA_DIR := src/parser/test_data
CMAKE_BUILD_TYPE ?= Debug

# Tools
MKDIR_P := mkdir -p
VALGRIND := valgrind
PERF := perf
HELGRIND := valgrind --tool=helgrind
CPPCHECK := cppcheck
CLANG_FORMAT := clang-format

# Valgrind options
VALGRIND_OPTS := --leak-check=full --show-leak-kinds=all --track-origins=yes \
                 --verbose --log-file=valgrind-out.txt --error-exitcode=1

# Helgrind options
HELGRIND_OPTS := --log-file=helgrind-out.txt --error-exitcode=1

# Perf options for 'perf stat'
PERF_STAT_OPTS := stat -e cycles,instructions,cache-references,cache-misses,branches,branch-misses

# Perf options for 'perf record' (for flame graphs)
PERF_RECORD_OPTS := record -F 99 -g --call-graph dwarf

# FlameGraph tools path (YOU MUST ADJUST THIS TO WHERE YOU CLONED FlameGraph)
FLAMEGRAPH_DIR := $(HOME)/FlameGraph

# Code formatting
IGNORE_DIRS := -path ./build -o -path ./cmake-build-debug -o -path ./bin
FORMAT_STYLE :=

# ==============================================================================
# Main Targets
# ==============================================================================
.PHONY: all
all: clean format build test

.PHONY: build
build: build_debug

.PHONY: build_debug
build_debug:
	@echo "┏=========================================┓"
	@echo "┃      BUILDING DEBUG VERSION             ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S . -DCMAKE_BUILD_TYPE=Debug
	cmake --build $(BUILD_DIR)
	@echo "✓ Build complete: $(BUILD_DIR)/src/parser/parser"

.PHONY: build_release
build_release:
	@echo "┏=========================================┓"
	@echo "┃     BUILDING RELEASE VERSION            ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S . -DCMAKE_BUILD_TYPE=Release
	cmake --build $(BUILD_DIR)
	@echo "✓ Build complete: $(BUILD_DIR)/src/parser/parser"

# NEW TARGET FOR PROFILING: Release mode with debug symbols
.PHONY: build_perf
build_perf:
	@echo "┏=========================================┓"
	@echo "┃   BUILDING FOR PERFORMANCE ANALYSIS     ┃"
	@echo "┃ (Release build with debug symbols)      ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	# This sets Release mode, and overrides the C flags for that mode to add -g
	cmake -B $(BUILD_DIR) -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="-O3 -g"
	cmake --build $(BUILD_DIR)
	@echo "✓ Build complete: $(BUILD_DIR)/src/parser/parser"

.PHONY: build_sanitizer
build_sanitizer:
	@echo "┏=========================================┓"
	@echo "┃    BUILDING WITH SANITIZERS             ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S . -DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g"
	cmake --build $(BUILD_DIR)

.PHONY: build_coverage
build_coverage:
	@echo "┏=========================================┓"
	@echo "┃      BUILDING WITH COVERAGE             ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S . -DCMAKE_BUILD_TYPE=Coverage
	cmake --build $(BUILD_DIR)

.PHONY: build_thread_sanitizer
build_thread_sanitizer:
	@echo "┏=========================================┓"
	@echo "┃    BUILDING WITH THREAD SANITIZER       ┃"
	@echo "┗=========================================┛"
	$(MKDIR_P) $(BUILD_DIR)
	cmake -B $(BUILD_DIR) -S . -DENABLE_THREAD_SANITIZER=ON
	cmake --build $(BUILD_DIR)

# ==============================================================================
# Testing Targets
# ==============================================================================
.PHONY: test
test: test_units test_valgrind test_sanitizer test_static

.PHONY: test_units
test_units: build_debug
	@echo "┏=========================================┓"
	@echo "┃         RUNNING UNIT TESTS              ┃"
	@echo "┗=========================================┛"
	@if [ -f "$(BUILD_DIR)/src/libs/tree_parser/unit_tests/parser_tests" ]; then \
		$(BUILD_DIR)/src/libs/tree_parser/unit_tests/parser_tests; \
	else \
		echo "⚠ Unit tests not found. Skipping..."; \
	fi

.PHONY: test_valgrind
test_valgrind: build_debug generate_test_data
	@echo "┏=========================================┓"
	@echo "┃        VALGRIND MEMORY CHECK            ┃"
	@echo "┗=========================================┛"
	@for testfile in $(TEST_DATA_DIR)/test_*.conf; do \
		echo "Testing with $$testfile..."; \
		$(VALGRIND) $(VALGRIND_OPTS) $(BUILD_DIR)/src/parser/parser $$testfile > /dev/null; \
		if [ $$? -eq 0 ]; then \
			echo "✓ $$testfile: No memory leaks"; \
			cat valgrind-out.txt; \
		else \
			echo "✗ $$testfile: Memory leaks detected!"; \
			cat valgrind-out.txt; \
			exit 1; \
		fi; \
	done
	@echo "✓ All Valgrind tests passed"

.PHONY: test_helgrind
test_helgrind: build_debug generate_test_data
	@echo "┏=========================================┓"
	@echo "┃      HELGRIND DATA RACE CHECK           ┃"
	@echo "┗=========================================┛"
	@for testfile in $(TEST_DATA_DIR)/test_*.conf; do \
		echo "Testing with $$testfile..."; \
		$(HELGRIND) $(HELGRIND_OPTS) $(BUILD_DIR)/src/parser/parser $$testfile > /dev/null 2>&1; \
		if [ $$? -eq 0 ]; then \
			echo "✓ $$testfile: No data races"; \
		else \
			echo "⚠ $$testfile: Potential data races"; \
			cat helgrind-out.txt; \
		fi; \
	done

.PHONY: test_sanitizer
test_sanitizer: build_sanitizer generate_test_data
	@echo "┏=========================================┓"
	@echo "┃       ADDRESS SANITIZER CHECK           ┃"
	@echo "┗=========================================┛"
	@for testfile in $(TEST_DATA_DIR)/test_*.conf; do \
		echo "Testing with $$testfile..."; \
		$(BUILD_DIR)/src/parser/parser $$testfile > /dev/null; \
		if [ $$? -eq 0 ]; then \
			echo "✓ $$testfile: No memory errors"; \
		else \
			echo "✗ $$testfile: Memory errors detected!"; \
			exit 1; \
		fi; \
	done
	@echo "✓ All sanitizer tests passed"

.PHONY: test_static
test_static: test_cppcheck

.PHONY: test_cppcheck
test_cppcheck:
	@echo "┏=========================================┓"
	@echo "┃         STATIC ANALYSIS (cppcheck)      ┃"
	@echo "┗=========================================┛"
	@if command -v cppcheck >/dev/null 2>&1; then \
		$(CPPCHECK) --enable=all --inconclusive --std=c11 --force \
			--suppress=missingIncludeSystem \
			--error-exitcode=1 \
			--quiet \
			src/libs/stack/*.c src/libs/tree_parser/*.c src/parser/*.c \
			src/libs/stack/include/*.h src/libs/tree_parser/include/*.h; \
		echo "✓ cppcheck passed"; \
	else \
		echo "⚠ cppcheck not installed. Install with: sudo apt install cppcheck"; \
	fi

# ==============================================================================
# Code Formatting
# ==============================================================================
.PHONY: format
format:
	@echo "┏=========================================┓"
	@echo "┃         CODE FORMATTING                 ┃"
	@echo "┗=========================================┛"
	@find . \( $(IGNORE_DIRS) \) -prune -o \( -name "*.c" -o -name "*.h" \) \
		-print | xargs $(CLANG_FORMAT) -i -style=file:linters/.clang-format
	@echo "✓ Code formatted"

.PHONY: check_format
check_format:
	@echo "┏=========================================┓"
	@echo "┃      CHECKING CODE FORMATTING           ┃"
	@echo "┗=========================================┛"
	@find . \( $(IGNORE_DIRS) \) -prune -o \( -name "*.c" -o -name "*.h" \) \
		-print | xargs $(CLANG_FORMAT) -n -Werror -style=file:linters/.clang-format

# ==============================================================================
# Test Data Generation
# ==============================================================================
.PHONY: generate_test_data
generate_test_data:
	@echo "┏=========================================┓"
	@echo "┃      GENERATING TEST DATA               ┃"
	@echo "┗=========================================┛"
	@cd $(TEST_DATA_DIR) && \
	if [ ! -f test_1.conf ]; then \
		python3 data_gen.py 5 3; \
		python3 data_gen.py 10 5; \
		python3 data_gen.py 20 7; \
	else \
		echo "✓ Test data already exists"; \
	fi

.PHONY: clean_test_data
clean_test_data:
	@echo "Cleaning test data..."
	@rm -f $(TEST_DATA_DIR)/test_*.conf
	@echo "✓ Test data cleaned"

# ==============================================================================
# Installation & Distribution
# ==============================================================================
.PHONY: install
install: build_release
	@echo "┏=========================================┓"
	@echo "┃       INSTALLING PARSER                 ┃"
	@echo "┗=========================================┛"
	@$(MKDIR_P) $(BIN_DIR)
	@cp $(BUILD_DIR)/src/parser/parser $(BIN_DIR)/
	@echo "✓ Installed to $(BIN_DIR)/parser"

.PHONY: install_libs
install_libs: build_release
	@echo "┏=========================================┓"
	@echo "┃      INSTALLING LIBRARIES               ┃"
	@echo "┗=========================================┛"
	@$(MKDIR_P) $(BIN_DIR)/lib
	@$(MKDIR_P) $(BIN_DIR)/include
	@cp $(BUILD_DIR)/src/libs/tree_parser/libtree_parser.a $(BIN_DIR)/lib/
	@cp $(BUILD_DIR)/src/libs/stack/libtree_stack.a $(BIN_DIR)/lib/
	@cp src/libs/tree_parser/include/parser.h $(BIN_DIR)/include/
	@cp src/libs/stack/include/stack.h $(BIN_DIR)/include/
	@echo "✓ Libraries installed to $(BIN_DIR)/lib"
	@echo "✓ Headers installed to $(BIN_DIR)/include"

# ==============================================================================
# Benchmarking
# ==============================================================================
.PHONY: benchmark
benchmark: build_release
	@echo "┏=========================================┓"
	@echo "┃          BENCHMARK SUITE                ┃"
	@echo "┗=========================================┛"
	@./scripts/benchmark.sh

# ==============================================================================
# Cleaning
# ==============================================================================
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(BIN_DIR)
	@rm -f valgrind-out.txt helgrind-out.txt
	@rm -f perf-*.data perf-*.folded perf-*.svg perf.data perf.data.old
	@echo "✓ Clean complete"

.PHONY: distclean
distclean: clean clean_test_data
	@echo "✓ Distribution clean complete"

# ==============================================================================
# Help
# ==============================================================================
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make all              - Clean, format, build and test"
	@echo "  make build            - Build debug version"
	@echo "  make build_release    - Build release version"
	@echo "  make build_perf       - Build for performance analysis (Release + debug symbols)"
	@echo "  make test             - Run all tests"
	@echo "  make test_valgrind    - Memory leak detection"
	@echo "  make test_helgrind    - Data race detection"
	@echo "  make test_sanitizer   - Address sanitizer"
	@echo "  make test_perf        - Performance analysis (generates flame graphs)"
	@echo "  make format           - Format source code"
	@echo "  make install          - Install binary"
	@echo "  make install_libs     - Install libraries"
	@echo "  make benchmark        - Run benchmarks"
	@echo "  make clean            - Remove build artifacts"
	@echo "  make distclean        - Full clean including test data"