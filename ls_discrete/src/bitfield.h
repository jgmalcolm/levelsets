#ifndef __BITFIELD_H
#define __BITFIELD_H

#include <stdlib.h>

typedef unsigned int uint;
typedef unsigned char bf_t;

/* Note, zero-index into fields, i.e. (0,0) is top left. */

/* print out bitfield in matrix form */
void bf_printf(const bf_t *bf, uint m, uint n);
/* reset the bitfield */
void bf_reset(bf_t *bf, uint m, uint n);

#define UNIT (sizeof(bf_t)*8)

#define BF_MASK(m, n, r, c) \
    (1 << (((m)*(n) - 1 - ((r)*(n)+(c))) % UNIT))
#define BF_BASE(m, n, r, c) \
    ((uint)((float)((r)*(n) + (c)) / (float)UNIT))

#define BF_SIZE(m, n) \
    ((m)*(n)/UNIT + (((m)*(n) % UNIT == 0)? 0 : 1))

/* initialize resident on the automatic variable stack */
#define BF_INIT(bf, m, n) \
    bf_t (bf)[BF_SIZE((m),(n))]; \
    bf_reset((bf), (m), (n));

/* initialize resident in the heap */
#define BF_INIT_SET(bf, m, n) \
    (bf) = JM_MALLOC(BF_SIZE((m),(n)));         \
    bf_reset((bf), (m), (n));

/* test */
#define BF_TEST(bf, m, n, r, c) \
    (((bf)[BF_BASE((m),(n),(r),(c))] & BF_MASK((m),(n),(r),(c))) != 0)

/* guarded test (if out of bounds => false, else return BF_TEST) */
#define BF_TEST_GUARDED(bf, m, n, r, c) /* See TODO below */ \
    (0 <= r && r <= m-1 && 0 <= c && c <= n-1 && \
     (((bf)[BF_BASE((m),(n),(r),(c))] & BF_MASK((m),(n),(r),(c))) != 0))

/* test if neighbor (only top/left/right/bottom) set (guarded) */
#define BF_TEST_GUARDED_NEIGHBOR(bf, m, n, r, c) \
    (BF_TEST_GUARDED((bf),(m),(n), (r)-1,(c)  ) || /* top */    \
     BF_TEST_GUARDED((bf),(m),(n), (r)  ,(c)-1) || /* left */   \
     BF_TEST_GUARDED((bf),(m),(n), (r)  ,(c)+1) || /* right */  \
     BF_TEST_GUARDED((bf),(m),(n), (r)+1,(c)  ))   /* bottom */

/* test if neighbor (only top/left/right/bottom) set (un-guarded) */
#define BF_TEST_NEIGHBOR(bf, m, n, r, c) \
    (BF_TEST((bf),(m),(n), (r)-1,(c)  ) || /* top */    \
     BF_TEST((bf),(m),(n), (r)  ,(c)-1) || /* left */   \
     BF_TEST((bf),(m),(n), (r)  ,(c)+1) || /* right */  \
     BF_TEST((bf),(m),(n), (r)+1,(c)  ))   /* bottom */

/* set operation */
#define BF_SET(bf, m, n, r, c) \
    ((bf)[BF_BASE((m),(n),(r),(c))] |= BF_MASK((m),(n),(r),(c)))
#define BF_RES(bf, m, n, r, c) \
    ((bf)[BF_BASE((m),(n),(r),(c))] &= (~BF_MASK((m),(n),(r),(c))))


#endif /* __BITFIELD_H */


/* example:

       uint m = 20, n = 40;
       BF_INIT(bf, m, n);

       BF_SET(bf, m, n, 4, 5);

       if (BF_TEST(bf, m, n, 4, 5))
           printf("is set");
       else
           printf("is not set");
       BF_RES(bf,m,n, 4,5);

       bf_t *bf2;
       BF_INIT_MALLOC(bf2, m, n);
       BF_SET(bf2, m, n, 17, 0);
*/



/* TODO: Implement BF_UNION(a,b,c) which stores the union of two bitfields, a
 * and b, into c. */

/* TODO: Not sure if compiler smart enough to optimize the BF_TEST_GUARDED
 * logic.  Maybe have to code each of those cases by hand, e.g. only checks
 * 0<i when testing top neighbor, not all four cases. */
