#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

#include "jm.h"
#include "ls_discrete.h"
#include "speed.h"
#include "move.h"

/* Note, zero level set is considered inside */

static int dim[3];
static int8 *phi_;
struct move_t *m;
struct icoll_t *C_;
struct speed_t *speed_handler_;

/* accessors */
static int8 phi_get(struct pt_t *p) {
    return phi_[(p->z*dim[1] + p->x)*dim[0] + p->y];
}
static void phi_set(struct pt_t *p, int8 v) {
    phi_[(p->z*dim[1] + p->x)*dim[0] + p->y] = v;
}



/* add neighbor points with opposite sign */
static void add(struct pt_t *p)
{
    struct pt_t *p_ = icoll_add_inplace(C_);
    *p_ = *p;

    if (phi_get(p) > 0) {
        p->phi = -1; /* (-) force to put on interface */
        move_put(m, p); /* move in */
    }
    phi_set(p_, 0);
}
void add_neighbors(struct icoll_t *C, struct pt_t *p)
{
    C_ = C;
    struct pt_t n;

    n.x = p->x; n.y = p->y + 1; n.z = p->z;
    if (n.y < dim[0] && phi_get(&n) * p->phi < 0)    add(&n);

    n.x = p->x + 1; n.y = p->y; n.z = p->z;
    if (n.x < dim[1] && phi_get(&n) * p->phi < 0)    add(&n);

    n.x = p->x; n.y = p->y; n.z = p->z + 1;
    if (n.z < dim[2] && phi_get(&n) * p->phi < 0)    add(&n);

    n.x = p->x; n.y = p->y - 1; n.z = p->z;
    if (1 <= p->y && phi_get(&n) * p->phi < 0)       add(&n);

    n.x = p->x - 1; n.y = p->y; n.z = p->z;
    if (1 <= p->x && phi_get(&n) * p->phi < 0)       add(&n);

    n.x = p->x; n.y = p->y; n.z = p->z - 1;
    if (1 <= p->z && phi_get(&n) * p->phi < 0)       add(&n);
}




/* ensure (+) and (-) don't touch, i.e. intervening zero */
/* if became (+/-), set all (-/+) neighbors to zero */
/* --> insert all these neighbors into replacing current point */
static void *force(void *vp, void *vC)
{
    struct pt_t *p = vp;
    struct icoll_t *C = vC;

    if (p->phi == 0) {
        /* no sign change--retain point */
        icoll_add(C, p);
    } else {
        /* evolve point */
        add_neighbors(C, p); /* add neighbors of opposite sign */

        /* destroy old point (not on interface anymore) */
        phi_set(p, p->phi);
        if (p->phi > 0)
            move_put(m, p);
    }

    return C;
}





/* drop points that violate minimal interface */
static bool cleanup(void *vp)
{
    struct pt_t *p = vp;

    /* grab phi in all directions (default: zero) */
    int8 n4[] = { 0, 0, 0, 0, 0, 0 };
    struct pt_t n;
    n.x = p->x; n.y = p->y + 1; n.z = p->z; /* down */
    if (n.y < dim[0])    n4[0] = phi_get(&n);
    n.x = p->x + 1; n.y = p->y; n.z = p->z; /* right */
    if (n.x < dim[1])    n4[1] = phi_get(&n);
    n.x = p->x; n.y = p->y; n.z = p->z + 1; /* backward */
    if (n.z < dim[2])    n4[2] = phi_get(&n);
    n.x = p->x; n.y = p->y - 1; n.z = p->z; /* up */
    if (1 <= p->y)       n4[3] = phi_get(&n);
    n.x = p->x - 1; n.y = p->y; n.z = p->z; /* left */
    if (1 <= p->x)       n4[4] = phi_get(&n);
    n.x = p->x; n.y = p->y; n.z = p->z - 1; /* forward */
    if (1 <= p->z)       n4[5] = phi_get(&n);

    /* determine dominant sign */
    int8 sign = 0; /* default: mixed signs */
    if (n4[0] >= 0 && n4[1] >= 0 && n4[2] >= 0 &&
        n4[3] >= 0 && n4[4] >= 0 && n4[5] >= 0)
        sign = 1; /* all (+) or interface */
    else if (n4[0] <= 0 && n4[1] <= 0 && n4[2] <= 0 &&
             n4[3] <= 0 && n4[4] <= 0 && n4[5] <= 0)
        sign = -1; /* all (-) or interface */
    else
        return false; /* retain point */

    /* drop point */
    p->phi = sign;
    phi_set(p, p->phi);
    if (sign > 0)
        move_put(m, p);

    return true; /* drop */
}





/* make a pass through the curve */
static struct icoll_t *evolve(struct icoll_t *C)
{
    struct icoll_t *C_ = icoll_new(sizeof(struct pt_t));
    C_ = icoll_fold(C, force, C_);
    icoll_delete(C_, cleanup, NULL);
    move_flush(m, speed_handler_);
    return C_;
}



static void contract(void *vp) {struct pt_t *p=vp; if (p->phi > 0) p->phi = 0;}
static void dilate(void *vp)   {struct pt_t *p=vp; if (p->phi < 0) p->phi = 0;}




struct icoll_t *ls_discrete(int8 *phi, const int *phi_dim,
                            struct icoll_t *C,
                            const unsigned int iter,
                            struct speed_t *speed_handler)
{
    dim[0] = phi_dim[0];
    dim[1] = phi_dim[1];
    dim[2] = phi_dim[2];
    phi_ = phi;
    m = move_init(dim);
    speed_handler_ = speed_handler;

    /*== main loop ==*/
    for (int i = 0; i < iter; i++) {
        speed_handler->init_iteration(phi, C);
        icoll_map(C, contract);
        struct icoll_t *C_ = evolve(C);
        speed_handler->init_iteration(phi, C_);
        icoll_map(C, dilate);
        C = evolve(C_);
    }

    move_free(m);
    return C;
}
