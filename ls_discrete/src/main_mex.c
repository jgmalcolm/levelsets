#include <stdio.h>
#include <string.h>
#include <mex.h>

#include "jm.h"
#include "icoll.h"
#include "speed.h"
#include "ls_discrete.h"

/* Note, assumes one-indexed point references from Matlab.  These are
 * transformed to/from zero-indexed for the algorithm.  */



static int usage(const char *msg)
{
    mexPrintf("error: %s\n"
              "\n"
              "usage: [phi C] = ls_discrete(phi, C, h, iter)\n"
              "  with h.{init_iteration, move_in, move_out}\n",
              msg);
    return 0;
}

/* 1 iff scalar */
static int is_scalar(const mxArray *m)
{
    const int dims_cnt = mxGetNumberOfDimensions(m);
    const mwSize *dims = mxGetDimensions(m);
    return dims_cnt == 2 && dims[0] == 1 && dims[1] == 1;
}


static int check_usage(int nlhs, mxArray *plhs[],
                        int nrhs, const mxArray *prhs[])
{

    if (nrhs != 4)
        return usage("wrong number of inputs");
    if (nlhs != 2)
        return usage("wrong number of outputs");



    /* phi must be 2D ro 3D */
    const int dims_cnt = mxGetNumberOfDimensions(prhs[0]);
    if (dims_cnt != 2 && dims_cnt != 3)
        return usage("phi must be 2D or 3D");
    /* phi must be of int8 class */
    if (mxGetClassID(prhs[0]) != mxINT8_CLASS)
        return usage("phi must be int8");

    /* h */
    const mxArray *m_h = prhs[2];
    if (mxGetClassID(m_h) != mxSTRUCT_CLASS)
        return usage("h must be a struct");
    if (mxGetFieldNumber(m_h, "init_iteration") == -1 ||
        mxGetFieldNumber(m_h, "move_in") == -1 ||
        mxGetFieldNumber(m_h, "move_out") == -1)
        return usage("h missing fields");


    /* iter */
    const mxArray *m_iter = prhs[3];
    if (is_scalar(m_iter) == 0)
        return usage("iter must be scalar");
    const double iter = mxGetScalar(m_iter);
    if (iter <= 0)
        return usage("iter must be positive");

    return 1; /* passed inspection */
}




/*-- utilities --*/
static int i;
static double *arr;
static int dims[3];
void coll2array_helper(void *vp)
{
    struct pt_t *p = vp;
    arr[i++] = (p->z)*dims[0]*dims[1] + (p->x)*dims[0] + (p->y) + 1;
}
static void coll2array(struct icoll_t *C, double *a)
{
    i = 0;
    arr = a;
    icoll_map(C, coll2array_helper);
}
static struct icoll_t *array2coll(double *arr, int arr_len)
{
    struct icoll_t *C = icoll_new(sizeof(struct pt_t));
    for (int i = 0; i < arr_len; i++) {
        struct pt_t *p = icoll_add_inplace(C);
        int ind = (int)arr[i] - 1;
        p->z = ind / (dims[0] * dims[1]);
        ind %= dims[0] * dims[1];
        p->x = ind / dims[0];
        p->y = ind % dims[0];
        p->phi = 0; /* zero level set */
    }
    return C;
}



static double *speeds;
static void fetch_speed(void *vp)
{
    struct pt_t *p = vp;
    if (speeds[i] > 0)        p->phi = -1; /* push in */
    else if (speeds[i] < 0)   p->phi =  1; /* push out */
    else                      p->phi =  0; /* hold on */
    i += 1;
}

static mxArray *m_init_iteration;
static mxArray *m_phi_;
static void init_iteration(int8 *phi, struct icoll_t *C)
{
    /*-- (1) prepare curve --*/
    mxArray *m_C = mxCreateDoubleMatrix(1, icoll_count(C), mxREAL);
    coll2array(C, mxGetPr(m_C));

    /*-- (2) matlab callback --*/
    mxArray *prhs[] = { m_init_iteration, m_phi_, m_C };
    mxArray *m_S;
    mexCallMATLAB(1, &m_S, 3, prhs, "feval");
    mxDestroyArray(m_C); /* free contour points */

    /*-- (4) fetch assigned speeds --*/
    ASSERT(mxGetClassID(m_S) == mxDOUBLE_CLASS);
    speeds = mxGetPr(m_S);
    i = 0;
    icoll_map(C, fetch_speed);

    mxDestroyArray(m_S); /* free point speeds */
}
    


static void move(mxArray *m_fn, struct icoll_t *C)
{
    mxArray *m_pts = mxCreateDoubleMatrix(1, icoll_count(C), mxREAL);
    coll2array(C, mxGetPr(m_pts));
    mxArray *prhs[] = { m_fn, m_pts };
    mexCallMATLAB(0, NULL, 2, prhs, "feval");
}
static mxArray *m_move_in;
static mxArray *m_move_out;
static void move_in(struct icoll_t *C)  {move(m_move_in,  C);}
static void move_out(struct icoll_t *C) {move(m_move_out, C);}



void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    mexSetTrapFlag(1); /* bail to Matlab prompt on mexCallMATLAB error */
    /*-- check command arguments --*/
    if (check_usage(nlhs, plhs, nrhs, prhs) == 0)
        return;


    /*-- input --*/
    const mxArray *m_phi = prhs[0], *m_C = prhs[1], *m_speed = prhs[2];
    const mxArray *m_iter = prhs[3];
    const mwSize *phi_dims = mxGetDimensions(m_phi);
    dims[0] = phi_dims[0];
    dims[1] = phi_dims[1];
    dims[2] = mxGetNumberOfDimensions(m_phi) == 3 ? phi_dims[2] : 1;
    struct icoll_t *C = array2coll(mxGetPr(m_C), mxGetNumberOfElements(m_C));
    int iter = mxGetScalar(m_iter);


    /*-- output --*/
    m_phi_ = plhs[0] = mxDuplicateArray(m_phi); /* copies input */
    int8 *phi = mxGetData(m_phi_);



    /*-- construct callbacks --*/
    m_move_in = mxGetField(m_speed, 0, "move_in");
    m_move_out = mxGetField(m_speed, 0, "move_out");
    m_init_iteration = mxGetField(m_speed, 0, "init_iteration");


    /*-- run --*/
    struct speed_t speed_fn = { init_iteration, move_in, move_out };
    ls_discrete(phi, dims, C, iter, &speed_fn);


    /*-- return C to array --*/
    plhs[1] = mxCreateDoubleMatrix(1, icoll_count(C), mxREAL);
    coll2array(C, mxGetPr(plhs[1]));
    icoll_free(C, NULL);
}
