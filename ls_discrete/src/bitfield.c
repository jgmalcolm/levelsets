#include <stdio.h>
#include <string.h>

#include "bitfield.h"

void bf_printf(const bf_t *bf, uint m, uint n)
{
    /* print header */
    printf("     ");
    for (uint i = 0; i < n; i++)
        printf("%d", i % 10);
    printf("\n");
        
    for (uint i = 0; i < m; i++) {
        printf("%3d: ", i);
        for (uint j = 0; j < n; j++)
            printf("%d", 1 == BF_TEST(bf,m,n, i,j));
        printf("\n");
    }
}

void bf_reset(bf_t *bf, uint m, uint n)
{
    for (uint i = 0; i < BF_SIZE(m,n); i++)
        bf[i] = 0;
}
