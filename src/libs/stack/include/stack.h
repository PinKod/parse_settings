//
// Created by pinkod on 10/24/25.
//

#ifndef STACK_H
#define STACK_H

#include <stddef.h>

typedef struct stack* stack_t;

typedef enum {
    STACK_SUCCESS = 0,
    STACK_ERROR_NULL_PTR,
    STACK_ERROR_OVERFLOW,
    STACK_ERROR_UNDERFLOW,
    STACK_ERROR_MEMORY
} stack_error_t;

stack_t stack_init(size_t max_depth);
void stack_destroy(stack_t stack);

stack_error_t stack_push(stack_t stack, void* value);
stack_error_t stack_pop(stack_t stack, void** value);

stack_error_t stack_peek(stack_t stack, void** value);

int stack_is_empty(stack_t stack);
int stack_is_full(stack_t stack);
size_t stack_size(stack_t stack);
size_t stack_max_depth(stack_t stack);

const char* stack_error_string(stack_error_t error);

#endif // STACK_H
