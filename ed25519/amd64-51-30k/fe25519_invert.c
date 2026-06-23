#include "fe25519.h"

void fe25519_invert(fe25519 *r, const fe25519 *x)
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
	
	 fe25519_square(&z2,x);
	 fe25519_square(&t,&z2);
	 fe25519_square(&t,&t);
	 fe25519_mul(&z9,&t,x);
	 fe25519_mul(&z11,&z9,&z2);
	 fe25519_square(&t,&z11);
	 fe25519_mul(&z2_5_0,&t,&z9);

	 fe25519_square(&t,&z2_5_0);
	 fe25519_nsquare(&t,4);
	 fe25519_mul(&z2_10_0,&t,&z2_5_0);

	 fe25519_square(&t,&z2_10_0);
	 fe25519_nsquare(&t,9);
	 fe25519_mul(&z2_20_0,&t,&z2_10_0);

	 fe25519_square(&t,&z2_20_0);
	 fe25519_nsquare(&t,19);
	 fe25519_mul(&t,&t,&z2_20_0);

	 fe25519_square(&t,&t);
	 fe25519_nsquare(&t,9);
	 fe25519_mul(&z2_50_0,&t,&z2_10_0);

	 fe25519_square(&t,&z2_50_0);
	 fe25519_nsquare(&t,49);
	 fe25519_mul(&z2_100_0,&t,&z2_50_0);

	 fe25519_square(&t,&z2_100_0);
	 fe25519_nsquare(&t,99);
	 fe25519_mul(&t,&t,&z2_100_0);

	 fe25519_square(&t,&t);
	 fe25519_nsquare(&t,49);
	 fe25519_mul(&t,&t,&z2_50_0);

	 fe25519_square(&t,&t);
	 fe25519_square(&t,&t);
	 fe25519_square(&t,&t);

	 fe25519_square(&t,&t);

	 fe25519_square(&t,&t);
	 fe25519_mul(r,&t,&z11);
}
