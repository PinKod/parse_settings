//
// Created by pinkod on 10/24/25.
//
#include "include/stack_parser.h"

#include "../../include/macro.h"
#include "../stack/include/stack.h"
#include "include/parsers_common.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// private structs definition
struct attr {
    char* name;
    char* value;
    struct attr* next;
};

struct node {
    char* name;
    struct attr* attr;
    struct node* next;
    struct node* child;
};



// private functions declaration
static char* parse_name(struct parser* p);
static char* parse_quoted_value(struct parser* p, const char quote);
static char* parse_unquoted_value(struct parser* p);
static char* parse_value(struct parser* p);
static struct attr* parse_attribute(struct parser* p);


// public functions definition
parse_root_tuple parse_root_node(const char* input) {
    struct parser p = {input, 0};
    parse_root_tuple result = {NULL, PARSER_SUCCESS};

    skip_whitespace(&p);

    if(is_eof(&p)) {
        fprintf(stderr, "Error: Empty input\n");
        result.error = PARSER_ERROR_SYNTAX;
        return result;
    }

    if(current_char(&p) != '[') {
        fprintf(stderr, "Error: Expected '[' at start, got '%c'\n", current_char(&p));
        result.error = PARSER_ERROR_SYNTAX;
        return result;
    }


    stack_t node_stack = stack_init(100);
    if(INVERT_BOOL(node_stack)) {
        fprintf(stderr, "Error: Failed to initialize stack\n");
        result.error = PARSER_ERROR_MEMORY;
        return result;
    }

    struct node* root = NULL;
    struct node* current_parent = NULL;

    while(INVERT_BOOL(is_eof(&p))) {
        skip_whitespace(&p);

        if(is_eof(&p)) break;

        const char c = current_char(&p);

        if(c == '[') {

            p.pos++;

            char* name = parse_name(&p);
            if(INVERT_BOOL(name)) {
                fprintf(stderr, "Error at position %d: Expected node name after '['\n", p.pos);
                result.error = PARSER_ERROR_SYNTAX;
                if(root) free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }

            struct node* new_node = malloc(sizeof(struct node));
            if(INVERT_BOOL(new_node)) {
                fprintf(stderr, "Error: Memory allocation failed\n");
                free(name);
                result.error = PARSER_ERROR_MEMORY;
                if(root) free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }

            new_node->name = name;
            new_node->attr = NULL;
            new_node->next = NULL;
            new_node->child = NULL;


            if(INVERT_BOOL(root)) {
                root = new_node;
            } else if(current_parent) {
                if(INVERT_BOOL(current_parent->child)) {
                    current_parent->child = new_node;
                } else {

                    struct node* sibling = current_parent->child;
                    while(sibling->next) sibling = sibling->next;
                    sibling->next = new_node;
                }
            }


            if(stack_push(node_stack, current_parent) != STACK_SUCCESS) {
                fprintf(stderr, "Error: Stack overflow\n");
                result.error = PARSER_ERROR_STACK;
                free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }


            current_parent = new_node;

        } else if(c == ']') {

            p.pos++;


            void* prev_parent;
            if(stack_pop(node_stack, &prev_parent) != STACK_SUCCESS) {
                fprintf(stderr, "Error at position %d: Unexpected ']'\n", p.pos);
                result.error = PARSER_ERROR_SYNTAX;
                if(root) free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }
            current_parent = (struct node*) prev_parent;

        } else if(isalnum((unsigned char) c) || c == '_') {

            if(INVERT_BOOL(current_parent)) {
                fprintf(stderr, "Error at position %d: Attribute outside node\n", p.pos);
                result.error = PARSER_ERROR_SYNTAX;
                if(root) free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }

            struct attr* attr = parse_attribute(&p);
            if(INVERT_BOOL(attr)) {
                fprintf(stderr, "Error at position %d: Failed to parse attribute\n", p.pos);
                result.error = PARSER_ERROR_SYNTAX;
                if(root) free_root_node(root);
                stack_destroy(node_stack);
                return result;
            }


            if(INVERT_BOOL(current_parent->attr)) {
                current_parent->attr = attr;
            } else {
                struct attr* last = current_parent->attr;
                while(last->next) last = last->next;
                last->next = attr;
            }

        } else {
            fprintf(stderr, "Error at position %d: Unexpected character '%c' (0x%02x)\n", p.pos, c, (unsigned char) c);
            result.error = PARSER_ERROR_SYNTAX;
            if(root) free_root_node(root);
            stack_destroy(node_stack);
            return result;
        }
    }


    if(current_parent != NULL) {
        fprintf(stderr, "Error: Unclosed nodes (missing ']')\n");
        result.error = PARSER_ERROR_UNCLOSED_NODE;
        if(root) free_root_node(root);
        stack_destroy(node_stack);
        return result;
    }

    stack_destroy(node_stack);
    result.root = root;
    return result;
}


void print_root_node(node_t root) {
    if(INVERT_BOOL(root)) {
        printf("(empty tree)\n");
        return;
    }


    typedef struct {
        struct node* node;
        int level;
    } print_item;

    stack_t stack = stack_init(100);
    if(INVERT_BOOL(stack)) {
        fprintf(stderr, "Error: Failed to initialize print stack\n");
        return;
    }


    print_item* root_item = malloc(sizeof(print_item));
    if(INVERT_BOOL(root_item)) {
        stack_destroy(stack);
        return;
    }
    root_item->node = root;
    root_item->level = 0;
    stack_push(stack, root_item);

    while(INVERT_BOOL(stack_is_empty(stack))) {
        print_item* item;
        stack_pop(stack, (void**) &item);

        struct node* n = item->node;
        const int level = item->level;


        for(int i = 0; i < level; i++) printf("  ");
        printf("Node: %s\n", n->name);


        const struct attr* a = n->attr;
        while(a) {
            for(int i = 0; i < level + 1; i++) printf("  ");
            if(a->value && a->value[0]) {
                printf("Attr: %s = \"%s\"\n", a->name, a->value);
            } else {
                printf("Attr: %s (flag)\n", a->name);
            }
            a = a->next;
        }


        if(n->next) {
            print_item* next_item = malloc(sizeof(print_item));
            if(next_item) {
                next_item->node = n->next;
                next_item->level = level;
                stack_push(stack, next_item);
            }
        }

        if(n->child) {
            print_item* child_item = malloc(sizeof(print_item));
            if(child_item) {
                child_item->node = n->child;
                child_item->level = level + 1;
                stack_push(stack, child_item);
            }
        }

        free(item);
    }

    stack_destroy(stack);
}


void free_root_node(node_t root) {
    if(INVERT_BOOL(root)) return;

    stack_t stack = stack_init(100);
    if(INVERT_BOOL(stack)) {
        fprintf(stderr, "Error: Failed to initialize stack for free_root_node\n");
        return;
    }

    stack_push(stack, root);

    while(INVERT_BOOL(stack_is_empty(stack))) {
        struct node* current;
        if(stack_pop(stack, (void**) &current) != STACK_SUCCESS) { break; }


        if(current->next) { stack_push(stack, current->next); }
        if(current->child) { stack_push(stack, current->child); }


        struct attr* attr = current->attr;
        while(attr) {
            struct attr* next_attr = attr->next;
            if(attr->name) free(attr->name);
            if(attr->value) free(attr->value);
            free(attr);
            attr = next_attr;
        }


        if(current->name) free(current->name);
        free(current);
    }

    stack_destroy(stack);
}


// private functions definition


static char* parse_name(struct parser* p) {
    skip_whitespace(p);

    const char* start = p->input + p->pos;

    while(current_char(p) && (isalnum((unsigned char) current_char(p)) || current_char(p) == '_')) { p->pos++; }

    if(p->input + p->pos == start) { return NULL; }

    return strdup_range(start, p->input + p->pos);
}

static char* parse_quoted_value(struct parser* p, const char quote) {
    if(current_char(p) != quote) { return NULL; }

    p->pos++;

    char* buffer = malloc(strlen(p->input) - p->pos + 1);
    if(INVERT_BOOL(buffer)) return NULL;

    int buffer_pos = 0;
    int escaped = 0;

    while(current_char(p) && (escaped || current_char(p) != quote)) {
        if(!escaped && current_char(p) == '\\') {
            escaped = 1;
            p->pos++;
            continue;
        }

        buffer[buffer_pos++] = current_char(p);
        escaped = 0;
        p->pos++;
    }

    buffer[buffer_pos] = '\0';

    if(current_char(p) != quote) {
        fprintf(stderr, "Error at position %d: Missing closing quote '%c'\n", p->pos, quote);
        free(buffer);
        return NULL;
    }

    p->pos++;

    char* result = strdup(buffer);
    free(buffer);
    return result;
}

static char* parse_unquoted_value(struct parser* p) {
    skip_whitespace(p);

    const char* start = p->input + p->pos;

    while(current_char(p) && !isspace((unsigned char) current_char(p)) && current_char(p) != ']' && current_char(p) != '[') {
        p->pos++;
    }

    if(p->input + p->pos == start) { return strdup(""); }

    return strdup_range(start, p->input + p->pos);
}

static char* parse_value(struct parser* p) {
    skip_whitespace(p);

    if(current_char(p) == '"' || current_char(p) == '\'') {
        return parse_quoted_value(p, current_char(p));
    } else {
        return parse_unquoted_value(p);
    }
}


static struct attr* parse_attribute(struct parser* p) {
    const int saved_pos = p->pos;

    char* name = parse_name(p);
    if(INVERT_BOOL(name)) {
        p->pos = saved_pos;
        return NULL;
    }

    skip_whitespace(p);

    char* value = NULL;


    if(current_char(p) == '=') {
        p->pos++;

        value = parse_value(p);
        if(INVERT_BOOL(value)) {
            fprintf(stderr, "Error at position %d: Expected value after '='\n", p->pos);
            free(name);
            return NULL;
        }
    } else {

        value = strdup("");
        if(INVERT_BOOL(value)) {
            free(name);
            return NULL;
        }
    }

    struct attr* attr = malloc(sizeof(struct attr));
    if(INVERT_BOOL(attr)) {
        free(name);
        free(value);
        return NULL;
    }

    attr->name = name;
    attr->value = value;
    attr->next = NULL;

    return attr;
}
