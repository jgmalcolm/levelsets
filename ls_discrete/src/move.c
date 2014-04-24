#include <stdlib.h>
#include "jm.h"
#include "move.h"
#include "icoll.h"

/* Note, assume points given to move are referenced nowhere else and so may be
 * freed when flushing */

struct move_t *move_init(const int dims[2])
{
    MALLOC_INIT(struct move_t, m, 1);
    m->in = icoll_new(sizeof(struct pt_t));
    m->out = icoll_new(sizeof(struct pt_t));
    m->y_dim = dims[0]; m->x_dim = dims[1];
    BF_INIT_SET(m->bf_in,  m->x_dim, m->y_dim);
    BF_INIT_SET(m->bf_out, m->x_dim, m->y_dim);
    return m;
}
void move_flush(struct move_t *m, const struct speed_t *s)
{
    /*-- (1) move points --*/
    s->move_in(m->in);
    s->move_out(m->out);

    /*-- (2) free points --*/
    icoll_empty(m->in, NULL);
    icoll_empty(m->out, NULL);
    bf_reset(m->bf_in, m->x_dim, m->y_dim);
    bf_reset(m->bf_out, m->x_dim, m->y_dim);
}


static struct pt_t *b;
static bool is_equal(void *va)
{
    struct pt_t *a = va;
    return a->x == b->x && a->y == b->y;
}
static void put(struct move_t *m, struct pt_t *p,
                bf_t *bf, struct icoll_t *C,
                bf_t *bf_other, struct icoll_t *C_other)
{
    /* present in other? */
    if (BF_TEST(bf_other, m->x_dim, m->y_dim, p->x, p->y)) {
        /* remove to cancel out the effect */
        BF_RES(bf_other, m->x_dim, m->y_dim, p->x, p->y);
        b = p;
        icoll_delete(C_other, is_equal, NULL);
    } else {
        /* put in collection */
        icoll_add(C, p);
        BF_SET(bf, m->x_dim, m->y_dim, p->x, p->y);
    }
}

void move_put(struct move_t *m, struct pt_t *p)
{
    if (p->phi < 0)    put(m, p, m->bf_in,  m->in,  m->bf_out, m->out);
    else               put(m, p, m->bf_out, m->out, m->bf_in,  m->in);
}

void move_free(struct move_t *m)
{
    icoll_free(m->in, NULL);
    icoll_free(m->out, NULL);
}
