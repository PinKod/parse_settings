cmake_minimum_required(VERSION 3.21)
project(parser C)

# ==============================================================================
# Build Configuration
# ==============================================================================
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Определяем типы конфигураций
set(CMAKE_CONFIGURATION_TYPES "Debug;Release;Coverage;Sanitizer" CACHE STRING "" FORCE)

# Устанавливаем Debug по умолчанию
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# ==============================================================================
# Compiler Flags
# ==============================================================================

# Debug flags
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -O0 -Wall -Wextra -Wpedantic")

# Release flags
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -DNDEBUG -march=native")

# Coverage flags
set(CMAKE_C_FLAGS_COVERAGE
        "-g -O0 --coverage -fprofile-arcs -ftest-coverage"
        CACHE STRING "Coverage flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_COVERAGE
        "--coverage -fprofile-arcs -ftest-coverage"
        CACHE STRING "Coverage linker flags" FORCE)

# Sanitizer flags (Address + Undefined Behavior)
set(CMAKE_C_FLAGS_SANITIZER
        "-g -O1 -fsanitize=address,undefined -fno-omit-frame-pointer -fno-optimize-sibling-calls"
        CACHE STRING "Sanitizer flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_SANITIZER
        "-fsanitize=address,undefined"
        CACHE STRING "Sanitizer linker flags" FORCE)

# Thread Sanitizer (альтернатива для Helgrind)
option(ENABLE_THREAD_SANITIZER "Enable thread sanitizer" OFF)
if(ENABLE_THREAD_SANITIZER)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=thread -g -O1")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=thread")
endif()

# ==============================================================================
# Options
# ==============================================================================
option(BUILD_TESTS "Build unit tests" ON)
option(ENABLE_VALGRIND "Enable Valgrind tests" ON)
option(ENABLE_PERF "Enable performance profiling" OFF)

# ==============================================================================
# Dependencies
# ==============================================================================
if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    find_program(GCOV_PATH gcov)
    find_program(LCOV_PATH lcov)
    find_program(GENHTML_PATH genhtml)

    if(NOT GCOV_PATH OR NOT LCOV_PATH OR NOT GENHTML_PATH)
        message(WARNING "gcov/lcov/genhtml not found. Coverage report will be limited.")
    endif()
endif()

if(ENABLE_VALGRIND)
    find_program(VALGRIND_PATH valgrind)
    if(NOT VALGRIND_PATH)
        message(WARNING "Valgrind not found. Memory tests will be skipped.")
    endif()
endif()

# ==============================================================================
# Subdirectories
# ==============================================================================
add_subdirectory(src)

# ==============================================================================
# Testing (CTest integration)
# ==============================================================================
if(BUILD_TESTS)
    enable_testing()

    # Custom test targets
    add_custom_target(test_units
            COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            COMMENT "Running unit tests"
    )

    if(ENABLE_VALGRIND AND VALGRIND_PATH)
        add_custom_target(test_valgrind
                COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/run_valgrind.sh
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Running Valgrind memory tests"
        )
    endif()

    if(CMAKE_BUILD_TYPE STREQUAL "Sanitizer")
        add_custom_target(test_sanitizer
                COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/run_sanitizer.sh
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Running sanitizer tests"
        )
    endif()

    if(CMAKE_BUILD_TYPE STREQUAL "Coverage" AND LCOV_PATH)
        add_custom_target(test_coverage
                COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/generate_coverage.sh
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Generating coverage report"
        )
    endif()
endif()

# ==============================================================================
# Installation
# ==============================================================================
set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/bin" CACHE PATH "Installation directory" FORCE)

# ==============================================================================
# Summary
# ==============================================================================
message(STATUS "")
message(STATUS "========================================")
message(STATUS "  Project: ${PROJECT_NAME}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Standard: ${CMAKE_C_STANDARD}")
message(STATUS "  Compiler: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "  Build tests: ${BUILD_TESTS}")
if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    message(STATUS "  Coverage: ENABLED")
endif()
if(CMAKE_BUILD_TYPE STREQUAL "Sanitizer")
    message(STATUS "  Sanitizer: ENABLED")
endif()
message(STATUS "========================================")
message(STATUS "")