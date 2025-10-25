#include "stack.h"

#include "./../../include/macro.h"

#include <stdlib.h>
#include <string.h>

struct stack {
    void** data;
    size_t top;
    size_t max_depth;
    size_t element_size;
};

stack_t stack_init(const size_t max_depth) {
    if(max_depth == 0) return NULL;

    struct stack* new_stack = malloc(sizeof(struct stack));
    if(INVERT_BOOL(new_stack)) { return NULL; }

    new_stack->data = malloc(sizeof(void*) * max_depth);
    if(INVERT_BOOL(new_stack->data)) {
        free(new_stack);
        return NULL;
    }

    new_stack->top = 0;
    new_stack->max_depth = max_depth;
    new_stack->element_size = sizeof(void*);

    return new_stack;
}

void stack_destroy(stack_t stack) {
    if(stack) {
        free(stack->data);
        free(stack);
    }
}

stack_error_t stack_push(stack_t stack, void* value) {
    if(INVERT_BOOL(stack)) { return STACK_ERROR_NULL_PTR; }

    if(stack->top >= stack->max_depth) { return STACK_ERROR_OVERFLOW; }

    stack->data[stack->top++] = value;
    return STACK_SUCCESS;
}

stack_error_t stack_pop(stack_t stack, void** value) {
    if(INVERT_BOOL(stack)) { return STACK_ERROR_NULL_PTR; }

    if(stack->top == 0) { return STACK_ERROR_UNDERFLOW; }

    if(value) {
        *value = stack->data[--stack->top];
    } else {
        stack->top--;
    }

    return STACK_SUCCESS;
}

stack_error_t stack_peek(stack_t stack, void** value) {
    if(INVERT_BOOL(stack) || INVERT_BOOL(value)) { return STACK_ERROR_NULL_PTR; }

    if(stack->top == 0) { return STACK_ERROR_UNDERFLOW; }

    *value = stack->data[stack->top - 1];
    return STACK_SUCCESS;
}

int stack_is_empty(stack_t stack) { return stack ? (stack->top == 0) : 1; }

int stack_is_full(stack_t stack) { return stack ? (stack->top >= stack->max_depth) : 1; }

size_t stack_size(stack_t stack) { return stack ? stack->top : 0; }

size_t stack_max_depth(stack_t stack) { return stack ? stack->max_depth : 0; }

const char* stack_error_string(const stack_error_t error) {
    switch(error) {
        case STACK_SUCCESS:
            return "Success";
        case STACK_ERROR_NULL_PTR:
            return "Null pointer error";
        case STACK_ERROR_OVERFLOW:
            return "Stack overflow";
        case STACK_ERROR_UNDERFLOW:
            return "Stack underflow";
        case STACK_ERROR_MEMORY:
            return "Memory allocation error";
        default:
            return "Unknown error";
    }
}
