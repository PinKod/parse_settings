cmake_minimum_required(VERSION 3.21)
project(tree_parser C)

set(CMAKE_C_STANDARD 11)


add_library(${PROJECT_NAME} STATIC
        parser.c
)

target_include_directories(${PROJECT_NAME}
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../../include
        ${CMAKE_CURRENT_SOURCE_DIR}/../stack/include
)

target_link_libraries(${PROJECT_NAME}
        PRIVATE
        tree_stack
)


if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    target_compile_options(${PROJECT_NAME} PRIVATE --coverage)
    target_link_libraries(${PROJECT_NAME} PRIVATE gcov)
endif()


install(TARGETS ${PROJECT_NAME}
        ARCHIVE DESTINATION lib
)

install(FILES include/parser.h
        DESTINATION include
)