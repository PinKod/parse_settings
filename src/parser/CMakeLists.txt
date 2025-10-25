cmake_minimum_required(VERSION 3.21)
project(parser_executable C)

set(CMAKE_C_STANDARD 11)


add_executable(parser
        main.c
)

target_include_directories(parser
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../include
        ${CMAKE_CURRENT_SOURCE_DIR}/../libs/tree_parser/include
        ${CMAKE_CURRENT_SOURCE_DIR}/../libs/stack/include
)

target_link_libraries(parser
        PRIVATE
        tree_parser
        tree_stack
)


if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    target_link_libraries(parser PRIVATE gcov)
endif()


install(TARGETS parser
        RUNTIME DESTINATION bin
)


if(BUILD_TESTS)
    add_test(
            NAME parser_basic_test
            COMMAND parser ${CMAKE_SOURCE_DIR}/src/parser/test_data/test.conf
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

    set_tests_properties(parser_basic_test PROPERTIES
            PASS_REGULAR_EXPRESSION "Node:"
    )
endif()