//
// Created by pinkod on 10/24/25.
//

#ifndef MACRO_H
#define MACRO_H

#define INVERT_BOOL(x) (!(x))
#define CHECK_MEM(x) if(x)
#define FAIL_EXIT(res_val, res_var, resource_free_deffer)                                                                        \
    do {                                                                                                                         \
        res_var = res_val;                                                                                                       \
        goto resource_free_deffer;                                                                                               \
    } while(0)

#endif // MACRO_H
