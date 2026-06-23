#include "fe25519.h"

void fe25519_pow2523(fe25519 *r, const fe25519 *x)
{
	fe25519 z2;
	fe25519 z9;
	fe25519 z11;
	fe25519 z2_5_0;
	fe25519 z2_10_0;
	fe25519 z2_20_0;
	fe25519 z2_50_0;
	fe25519 z2_100_0;
	fe25519 t;
	int i;
		
	 fe25519_square(&z2,x);
	 fe25519_square(&t,&z2);
	 fe25519_square(&t,&t);
	 fe25519_mul(&z9,&t,x);
	 fe25519_mul(&z11,&z9,&z2);
	 fe25519_square(&t,&z11);
	 fe25519_mul(&z2_5_0,&t,&z9);

	 fe25519_square(&t,&z2_5_0);
	 for (i = 1;i < 5;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&z2_10_0,&t,&z2_5_0);

	 fe25519_square(&t,&z2_10_0);
	 for (i = 1;i < 10;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&z2_20_0,&t,&z2_10_0);

	 fe25519_square(&t,&z2_20_0);
	 for (i = 1;i < 20;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&t,&t,&z2_20_0);

	 fe25519_square(&t,&t);
	 for (i = 1;i < 10;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&z2_50_0,&t,&z2_10_0);

	 fe25519_square(&t,&z2_50_0);
	 for (i = 1;i < 50;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&z2_100_0,&t,&z2_50_0);

	 fe25519_square(&t,&z2_100_0);
	 for (i = 1;i < 100;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&t,&t,&z2_100_0);

	 fe25519_square(&t,&t);
	 for (i = 1;i < 50;i++) { fe25519_square(&t,&t); }
	 fe25519_mul(&t,&t,&z2_50_0);

	 fe25519_square(&t,&t);
	 fe25519_square(&t,&t);
	 fe25519_mul(r,&t,x);
}
