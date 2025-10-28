cmake_minimum_required(VERSION 3.21)
project(tree_parser C)

set(CMAKE_C_STANDARD 11)


add_library(${PROJECT_NAME}_stack  STATIC
        stack_parser.c
)

target_include_directories(${PROJECT_NAME}_stack
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../../include
        ${CMAKE_CURRENT_SOURCE_DIR}/../stack/include
)

target_link_libraries(${PROJECT_NAME}_stack
        PRIVATE
        tree_stack
)


if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    target_compile_options(${PROJECT_NAME}_stack  PRIVATE --coverage)
    target_link_libraries(${PROJECT_NAME}_stack  PRIVATE gcov)
endif()


install(TARGETS ${PROJECT_NAME}_stack
        ARCHIVE DESTINATION lib
)

install(FILES include/stack_parser.h
        DESTINATION include
)