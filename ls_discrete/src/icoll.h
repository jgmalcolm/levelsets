/* in-place collection to avoid indirection */
#ifndef __ICOLL_H
#define __ICOLL_H

#include <stdlib.h>  /* size_t */

#define COLL_SIZE  (128)
#define COLL_RESIZE_FACTOR (2)

struct icoll_t {
    char *elements;
    size_t sz;        /* element size */
    size_t count;     /* current load */
    size_t max_count; /* max capacity for current sizing */
};

typedef void (*icoll_free_fn)(void *a);
typedef int (*icoll_cmp_fn)(void *a, void *b);
typedef bool (*icoll_test_fn)(void *a);
typedef void (*icoll_map_fn)(void *a);
typedef void *(*icoll_fold_fn)(void *a, void *init);

/*-- create/destroy --*/
struct icoll_t *icoll_new(size_t element_sz);
void icoll_compact(struct icoll_t *);
void icoll_empty(struct icoll_t *, icoll_free_fn); /* fn == NULL if no free */
void icoll_free(struct icoll_t *, icoll_free_fn); /* fn == NULL if no free */

/*-- add --*/
void icoll_add(struct icoll_t *, void *);
void *icoll_add_inplace(struct icoll_t *);
void icoll_append(struct icoll_t *, struct icoll_t *);

/*-- count --*/
size_t icoll_count(struct icoll_t *);
size_t icoll_count_if(struct icoll_t *, icoll_test_fn);

/*-- testing --*/
bool icoll_all(struct icoll_t *, icoll_test_fn);

/*-- traversing --*/
void icoll_map(struct icoll_t *, icoll_map_fn);

/*-- form new list of all elements that pass test_fn() == 1 */
struct icoll_t *icoll_filter(struct icoll_t *, icoll_test_fn);
/*-- filter yet remove those items from original icoll --*/
struct icoll_t *icoll_remove(struct icoll_t *, icoll_test_fn);
void icoll_delete(struct icoll_t *, icoll_test_fn, icoll_free_fn);

/*-- fold functionality --*/
void *icoll_fold(struct icoll_t *, icoll_fold_fn, void *init);


#endif
