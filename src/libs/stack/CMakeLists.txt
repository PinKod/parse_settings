cmake_minimum_required(VERSION 3.21)
project(tree_stack C)

set(CMAKE_C_STANDARD 11)


add_library(${PROJECT_NAME} STATIC
        stack.c
)

target_include_directories(${PROJECT_NAME}
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../../include
)


if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    target_compile_options(${PROJECT_NAME} PRIVATE --coverage)
    target_link_libraries(${PROJECT_NAME} PRIVATE gcov)
endif()


install(TARGETS ${PROJECT_NAME}
        ARCHIVE DESTINATION lib
)

install(FILES include/stack.h
        DESTINATION include
)