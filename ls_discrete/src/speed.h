#ifndef __SPEED_H
#define __SPEED_H

/* Create a closure so can reference phi and size(phi).  Do this via
 * continuations, i.e. speed calls ls_switching so that speed's activation
 * record and hence nested functions are available to ls_switching. */

#include "icoll.h"
#include "point.h"

typedef void (*init_iteration_fn)(int8 *phi, struct icoll_t *C);
typedef void (*move_fn)(struct icoll_t *C);

struct speed_t {
    init_iteration_fn init_iteration;
    move_fn move_in, move_out;
};

#endif /* __SPEED_H */
