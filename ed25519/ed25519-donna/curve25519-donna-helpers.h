
static void
curve25519_pow_two5mtwo0_two250mtwo0(bignum25519 b) {
	bignum25519 ALIGN(16) t0,c;

	 
	 curve25519_square_times(t0, b, 5);
	 curve25519_mul_noinline(b, t0, b);
	 curve25519_square_times(t0, b, 10);
	 curve25519_mul_noinline(c, t0, b);
	 curve25519_square_times(t0, c, 20);
	 curve25519_mul_noinline(t0, t0, c);
	 curve25519_square_times(t0, t0, 10);
	 curve25519_mul_noinline(b, t0, b);
	 curve25519_square_times(t0, b, 50);
	 curve25519_mul_noinline(c, t0, b);
	 curve25519_square_times(t0, c, 100);
	 curve25519_mul_noinline(t0, t0, c);
	 curve25519_square_times(t0, t0, 50);
	 curve25519_mul_noinline(b, t0, b);
}

static void
curve25519_recip(bignum25519 out, const bignum25519 z) {
	bignum25519 ALIGN(16) a,t0,b;

	 curve25519_square_times(a, z, 1); 
	 curve25519_square_times(t0, a, 2);
	 curve25519_mul_noinline(b, t0, z); 
	 curve25519_mul_noinline(a, b, a); 
	 curve25519_square_times(t0, a, 1);
	 curve25519_mul_noinline(b, t0, b);
	 curve25519_pow_two5mtwo0_two250mtwo0(b);
	 curve25519_square_times(b, b, 5);
	 curve25519_mul_noinline(out, b, a);
}

static const unsigned char curve25519_packedone[32] = {
	1, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
};

static void
curve25519_setone(bignum25519 out) {
	
	curve25519_expand(out, curve25519_packedone);
}

static void
curve25519_batchrecip(bignum25519 *out, const bignum25519 *in, bignum25519 *tmp, size_t num, size_t offset) {
	bignum25519 ALIGN(16) acc,tmpacc;
	size_t i;
	const bignum25519 *inp;
	bignum25519 *outp;

	curve25519_setone(acc);

	inp = in;
	for (i = 0; i < num; ++i) {
		curve25519_copy(tmp[i], acc);
		curve25519_mul(acc, acc, *inp);
		inp = (const bignum25519 *)((const char *)inp + offset);
	}

	curve25519_recip(acc, acc);

	i = num;
	inp = (const bignum25519 *)((const char *)in + offset * num);
	outp = (bignum25519 *)((char *)out + offset * num);
	while (i--) {
		inp = (const bignum25519 *)((const char *)inp - offset);
		outp = (bignum25519 *)((char *)outp - offset);
		curve25519_mul(tmpacc, acc, *inp);
		curve25519_mul(*outp, acc, tmp[i]);
		curve25519_copy(acc, tmpacc);
	}
}

static void
curve25519_pow_two252m3(bignum25519 two252m3, const bignum25519 z) {
	bignum25519 ALIGN(16) b,c,t0;

	 curve25519_square_times(c, z, 1); 
	 curve25519_square_times(t0, c, 2); 
	 curve25519_mul_noinline(b, t0, z); 
	 curve25519_mul_noinline(c, b, c); 
	 curve25519_square_times(t0, c, 1);
	 curve25519_mul_noinline(b, t0, b);
	 curve25519_pow_two5mtwo0_two250mtwo0(b);
	 curve25519_square_times(b, b, 2);
	 curve25519_mul_noinline(two252m3, b, z);
}
