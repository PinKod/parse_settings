//
// Created by pinkod on 10/28/25.
//

#ifndef COMMON_H
#define COMMON_H
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "macro.h"


struct parser {
    const char* input;
    int pos;
};


#define FORCE_INLINE inline __attribute__((always_inline))

FORCE_INLINE void skip_whitespace(struct parser* p) {
    while(p->input[p->pos] && isspace((unsigned char) p->input[p->pos])) { p->pos++; }
}

FORCE_INLINE char current_char(const struct parser* p) { return p->input[p->pos]; }

FORCE_INLINE int is_eof(const struct parser* p) { return p->input[p->pos] == '\0'; }

FORCE_INLINE char* strdup_range(const char* start, const char* end) {
    const size_t len = end - start;
    char* result = malloc(len + 1);
    if(INVERT_BOOL(result)) return NULL;
    memcpy(result, start, len);
    result[len] = '\0';
    return result;
}

#endif //COMMON_H
