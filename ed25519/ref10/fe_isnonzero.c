#include "fe.h"
#include "crypto_verify_32.h"


static const unsigned char zero[32];

int fe_isnonzero(const fe f)
{
  unsigned char s[32];
  fe_tobytes(s,f);
  return crypto_verify_32(s,zero);
}
