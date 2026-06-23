#include "fe25519.h"
#include "ge25519.h"

static const fe25519 ecd = {{929955233495203, 466365720129213, 1662059464998953, 2033849074728123, 1442794654840575}};

static const fe25519 sqrtm1 = {{1718705420411056, 234908883556509, 2233514472574048, 2117202627021982, 765476049583133}};

int ge25519_unpackneg_vartime(ge25519_p3 *r, const unsigned char p[32])
{
  fe25519 t, chk, num, den, den2, den4, den6;
  unsigned char par = p[31] >> 7;

  fe25519_setint(&r->z,1);
  fe25519_unpack(&r->y, p); 
  fe25519_square(&num, &r->y); 
  fe25519_mul(&den, &num, &ecd); 
  fe25519_sub(&num, &num, &r->z); 
  fe25519_add(&den, &r->z, &den); 

  
  fe25519_square(&den2, &den);
  fe25519_square(&den4, &den2);
  fe25519_mul(&den6, &den4, &den2);
  fe25519_mul(&t, &den6, &num);
  fe25519_mul(&t, &t, &den);

  fe25519_pow2523(&t, &t);
  
  fe25519_mul(&t, &t, &num);
  fe25519_mul(&t, &t, &den);
  fe25519_mul(&t, &t, &den);
  fe25519_mul(&r->x, &t, &den);

  
  fe25519_square(&chk, &r->x);
  fe25519_mul(&chk, &chk, &den);
  if (!fe25519_iseq_vartime(&chk, &num))
    fe25519_mul(&r->x, &r->x, &sqrtm1);

  
  fe25519_square(&chk, &r->x);
  fe25519_mul(&chk, &chk, &den);
  if (!fe25519_iseq_vartime(&chk, &num))
    return -1;

  
  if(fe25519_getparity(&r->x) != (1-par))
    fe25519_neg(&r->x, &r->x);

  fe25519_mul(&r->t, &r->x, &r->y);
  return 0;
}
