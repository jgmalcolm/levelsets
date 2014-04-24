#ifndef __MOVE_H
#define __MOVE_H

#include "point.h"
#include "speed.h"
#include "bitfield.h"
#include "icoll.h"

struct move_t {
    struct icoll_t *in, *out;
    uint x_dim, y_dim;
    bf_t *bf_in, *bf_out; /* fast lookup for duplicates */
};

struct move_t *move_init(const int dims[2]);
void move_flush(struct move_t *m, const struct speed_t *s);
void move_put(struct move_t *m, struct pt_t *p);
void move_free(struct move_t *m);

#endif
