//
// Created by pinkod on 10/24/25.
//
#include "../include/macro.h"
#include "../libs/tree_parser/include/parser.h"

#include <stdio.h>
#include <stdlib.h>

// private functions declaration
static FILE* open_file(int argc, char* argv[]);
static char* read_file(FILE* file);


// public functions definitions
int main(int argc, char* argv[]) {
    int res = 0;
    FILE* file = NULL;
    char* input = NULL;
    node_t root_node = NULL;

    file = open_file(argc, argv);
    if(INVERT_BOOL(file)) FAIL_EXIT(1, res, resource_free_defer);

    input = read_file(file);

    file = NULL;
    if(INVERT_BOOL(input)) FAIL_EXIT(2, res, resource_free_defer);

    const parse_root_tuple root_tuple = parse_root_node(input);
    if(root_tuple.error != PARSER_SUCCESS) {
        fprintf(stderr, "Parser error code: %d\n", root_tuple.error);
        FAIL_EXIT(3, res, resource_free_defer);
    }

    root_node = root_tuple.root;
    if(INVERT_BOOL(root_node)) FAIL_EXIT(3, res, resource_free_defer);

    print_root_node(root_node);

resource_free_defer:
    CHECK_MEM(input) free((void*) input);
    CHECK_MEM(root_node) free_root_node(root_node);
    return res;
}


// private functions definition
static FILE* open_file(const int argc, char* argv[]) {
    if(argc != 2) {
        fprintf(stderr, "Usage: %s <config_file>\n", argv[0]);
        return NULL;
    }

    FILE* file = fopen(argv[1], "r");
    if(INVERT_BOOL(file)) {
        perror("Failed to open file");
        return NULL;
    }

    return file;
}

static char* read_file(FILE* file) {
    fseek(file, 0, SEEK_END);
    const long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    char* input = malloc(length + 1);
    if(INVERT_BOOL(input)) {
        fclose(file);
        return NULL;
    }

    fread(input, 1, length, file);
    input[length] = '\0';
    fclose(file);

    return input;
}
