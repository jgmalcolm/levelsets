#include <string.h>
#include "jm.h"
#include "icoll.h"


#define ADDR(c,i) ((c)->elements + (c)->sz * (i))

struct icoll_t *icoll_new(size_t element_sz)
{
    MALLOC_INIT(struct icoll_t, c, 1);
    MALLOC_SET(char, c->elements, element_sz * COLL_SIZE);
    c->count = 0;
    c->max_count = COLL_SIZE;
    c->sz = element_sz;
    return c;
}

static void icoll_enlarge(struct icoll_t *c)
{
    c->max_count = c->max_count * COLL_RESIZE_FACTOR;
    REALLOC_SET(char, c->elements, c->sz * c->max_count);
}

void icoll_add(struct icoll_t *c, void *a)
{
    if (c->count == c->max_count)
        icoll_enlarge(c);
    memcpy(ADDR(c, c->count), a, c->sz);
    c->count += 1;
}
void *icoll_add_inplace(struct icoll_t *c)
{
    if (c->count == c->max_count)
        icoll_enlarge(c);
    c->count += 1;
    return ADDR(c, c->count - 1);
}

void icoll_append(struct icoll_t *to_c, struct icoll_t *from_c)
{
    ASSERT(to_c->sz == from_c->sz);

    while (to_c->max_count < to_c->count + from_c->count)
        icoll_enlarge(to_c);

    for (int i = 0; i < from_c->count; i++)
        memcpy(ADDR(to_c,   i + to_c->count),
               ADDR(from_c, i),
               to_c->sz);

    to_c->count += from_c->count;
}

void icoll_empty(struct icoll_t *c, icoll_free_fn free)
{
    if (free) {
        for (int i = 0; i < c->count; i++)
            free(ADDR(c, i));
    }
    c->count = 0;
}

void icoll_free(struct icoll_t *c, icoll_free_fn free_fn)
{
    icoll_empty(c, free_fn);
    JM_FREE(c);
}

size_t icoll_count(struct icoll_t *c)
{
    return c->count;
}

size_t icoll_count_if(struct icoll_t *c, icoll_test_fn test)
{
    size_t cnt = 0;
    for (int i = 0; i < c->count; i++)
        cnt += test(ADDR(c, i));
    return cnt;
}


bool icoll_all(struct icoll_t *c, icoll_test_fn test)
{
    for (int i = 0; i < c->count; i++) {
        if (!test(ADDR(c,i)))
            return false; /* fail */
    }
    return true; /* all passed */
}

void icoll_map(struct icoll_t *c, icoll_map_fn map)
{
    for (int i = 0; i < c->count; i++)
        map(ADDR(c, i));
}

struct icoll_t *icoll_filter(struct icoll_t *c, icoll_test_fn test)
{
    struct icoll_t *new_c = icoll_new(c->sz);

    for (int i = 0; i < c->count; i++) {
        if (test(ADDR(c, i)))
            icoll_add(new_c, ADDR(c, i));
    }

    return new_c;
}
struct icoll_t *icoll_remove(struct icoll_t *c, icoll_test_fn test)
{
    struct icoll_t *new_c = icoll_new(c->sz);

    for (int i = 0; i < c->count; i++) {
        if (test(ADDR(c, i))) {
            icoll_add(new_c, ADDR(c, i)); /* move */
            
            if (i < c->count - 1) { /* if not last, move last item here */
                memcpy(ADDR(c, i), ADDR(c, c->count-1), c->sz);
            }
            c->count += -1;

            /*-- (3) repeat on this one that has been moved here --*/
            i += -1;
        }
    }
    return new_c;
}

void *icoll_fold(struct icoll_t *c, icoll_fold_fn fn, void *init)
{
    for (int i = 0; i < c->count; i++)
        init = fn(ADDR(c, i), init);
    return init;
}

/* Assumption.  Iterate from start of array to end.  Modifications,
 * e.g. additions and removals, are seen later in the traversal.
 */
void icoll_delete(struct icoll_t *c, icoll_test_fn test, icoll_free_fn free)
{
    for (int i = 0; i < c->count; i++) {
        if (test(ADDR(c, i))) {
            /*-- (1) remove --*/
            if (free) free(ADDR(c, i));
            if (i < c->count - 1) { /* if not last, move last item here */
                memcpy(ADDR(c, i),
                       ADDR(c, c->count-1),
                       c->sz);
            }
            c->count += -1;

            /*-- (2) repeat on this one that has been moved here --*/
            i += -1;
        }
    }
}
