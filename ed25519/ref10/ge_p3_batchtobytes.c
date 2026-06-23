#include "ge.h"


void ge_p3_batchtobytes_destructive_1(bytes32 *out,ge_p3 *in,fe *tmp,size_t num)
{
  fe y;

  fe_batchinvert(&in->Z,&in->Z,tmp,num,sizeof(ge_p3));

  for (size_t i = 0;i < num;++i) {
    fe_mul(y,in[i].Y,in[i].Z);
    fe_tobytes(out[i],y);
  }
}

void ge_p3_batchtobytes_destructive_finish(bytes32 out,ge_p3 *unf)
{
  fe x;
  
  fe_mul(x,unf->X,unf->Z);
  out[31] ^= fe_isnegative(x) << 7;
}
