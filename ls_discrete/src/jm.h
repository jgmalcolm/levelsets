#ifndef __JM_H
#define __JM_H

#include <mex.h>

#define JM_MALLOC  mxMalloc
#define JM_FREE    mxFree
#define JM_REALLOC mxRealloc

#define MALLOC_INIT(ty, var, cnt)                   \
    ty *(var) = (ty *)JM_MALLOC( (cnt) * sizeof(ty) ); \
    mexMakeMemoryPersistent(var);

#define MALLOC_SET(ty, dest, cnt)               \
    dest = (ty *)JM_MALLOC( (cnt) * sizeof(ty) );         \
    mexMakeMemoryPersistent(dest);

#define REALLOC_SET(ty, dest, cnt)               \
    dest = (ty *)JM_REALLOC( dest, (cnt) * sizeof(ty) ); \
    mexMakeMemoryPersistent(dest);

#define MSG(msg) { char buf[100]; snprintf(buf, sizeof(buf), __FILE__":%d(%s) %s\n", __LINE__, __FUNCTION__, msg); mexPrintf(buf); }

#define MSG_(msg,val) { char buf[100]; snprintf(buf, sizeof(buf), __FILE__":%d(%s) %s %08x\n", __LINE__, __FUNCTION__, msg, val); mexPrintf(buf); }

#define SHOW(m) mexPrintf("%-20s %d  (%08x  %08x)\n", #m, mxIsSharedArray(m), m, mxGetData(m));

/* #define IS_SHARED(m) mexPrintf("is_shared(%s) %d\n", #m, mxIsSharedArray(m)); */

#define ASSERT(exp) mxAssert(exp, #exp);



/* Definitions to keep compatibility with earlier versions of ML */
#ifndef MWSIZE_MAX
typedef int mwSize;
typedef int mwIndex;
typedef int mwSignedIndex;

#if (defined(_LP64) || defined(_WIN64)) && !defined(MX_COMPAT_32)
/* Currently 2^48 based on hardware limitations */
# define MWSIZE_MAX    281474976710655UL
# define MWINDEX_MAX   281474976710655UL
# define MWSINDEX_MAX  281474976710655L
# define MWSINDEX_MIN -281474976710655L
#else
# define MWSIZE_MAX    2147483647UL
# define MWINDEX_MAX   2147483647UL
# define MWSINDEX_MAX  2147483647L
# define MWSINDEX_MIN -2147483647L
#endif
#define MWSIZE_MIN    0UL
#define MWINDEX_MIN   0UL
#endif


#endif
