#ifndef __LS_DISCRETE_H
#define __LS_DISCRETE_H

#include "speed.h"
#include "icoll.h"

struct icoll_t *ls_discrete(int8 *phi, const int *dim,
                            struct icoll_t *C,
                            const unsigned int iter,
                            struct speed_t *speed_h);


#endif
