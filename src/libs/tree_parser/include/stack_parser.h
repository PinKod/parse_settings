//
// Created by pinkod on 10/24/25.
//

#ifndef PARSER_H
#define PARSER_H

typedef struct node* node_t;

typedef enum {
    PARSER_SUCCESS = 0,
    PARSER_ERROR_SYNTAX,
    PARSER_ERROR_MEMORY,
    PARSER_ERROR_STACK,
    PARSER_ERROR_UNCLOSED_NODE,
    PARSER_ERROR_UNEXPECTED_EOF
} parser_error_t;

typedef struct {
    node_t root;
    parser_error_t error;
} parse_root_tuple;

parse_root_tuple parse_root_node(const char* input);
void print_root_node(node_t node);
void free_root_node(node_t node);


#endif // PARSER_H
