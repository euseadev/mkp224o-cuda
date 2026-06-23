#include "fe.h"


int fe_isnegative(const fe f)
{
  unsigned char s[32];
  fe_tobytes(s,f);
  return s[0] & 1;
}
