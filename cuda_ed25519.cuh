
#ifndef CUDA_ED25519_CUH
#define CUDA_ED25519_CUH

#include <stdint.h>

typedef struct { uint64_t lo, hi; } u128;

__device__ __forceinline__ u128 mul64x64_128(uint64_t a, uint64_t b) {
	u128 r;
	r.lo = a * b;
	r.hi = __umul64hi(a, b);
	return r;
}
__device__ __forceinline__ uint64_t lo128(const u128 &a) { return a.lo; }
__device__ __forceinline__ uint64_t hi128(const u128 &a) { return a.hi; }

__device__ __forceinline__ uint64_t shr128(const u128 &a, unsigned s) {
	return (a.lo >> s) | (a.hi << (64 - s));
}
__device__ __forceinline__ void add128(u128 &a, const u128 &b) {
	uint64_t t = a.lo;
	a.lo += b.lo;
	a.hi += b.hi + (a.lo < t);
}
__device__ __forceinline__ void add128_64(u128 &a, uint64_t b) {
	uint64_t t = a.lo;
	a.lo += b;
	a.hi += (a.lo < t);
}

typedef uint64_t fe[5];

#define MASK51 (((uint64_t)1 << 51) - 1)
#define MASK56 (((uint64_t)1 << 56) - 1)

__device__ __forceinline__ void fe_copy(fe out, const fe in) {
	out[0]=in[0]; out[1]=in[1]; out[2]=in[2]; out[3]=in[3]; out[4]=in[4];
}

__device__ __forceinline__ void fe_add(fe out, const fe a, const fe b) {
	out[0]=a[0]+b[0]; out[1]=a[1]+b[1]; out[2]=a[2]+b[2]; out[3]=a[3]+b[3]; out[4]=a[4]+b[4];
}
__device__ __forceinline__ void fe_add_after_basic(fe out, const fe a, const fe b) {
	fe_add(out, a, b);
}
__device__ __forceinline__ void fe_add_reduce(fe out, const fe a, const fe b) {
	uint64_t c;
	out[0]=a[0]+b[0]    ; c=out[0]>>51; out[0]&=MASK51;
	out[1]=a[1]+b[1]+c  ; c=out[1]>>51; out[1]&=MASK51;
	out[2]=a[2]+b[2]+c  ; c=out[2]>>51; out[2]&=MASK51;
	out[3]=a[3]+b[3]+c  ; c=out[3]>>51; out[3]&=MASK51;
	out[4]=a[4]+b[4]+c  ; c=out[4]>>51; out[4]&=MASK51;
	out[0] += c*19;
}

#define TWO_P0     ((uint64_t)0x0fffffffffffda)
#define TWO_P1234  ((uint64_t)0x0ffffffffffffe)
#define FOUR_P0    ((uint64_t)0x1fffffffffffb4)
#define FOUR_P1234 ((uint64_t)0x1ffffffffffffc)

__device__ __forceinline__ void fe_sub(fe out, const fe a, const fe b) {
	out[0]=a[0]+TWO_P0    -b[0];
	out[1]=a[1]+TWO_P1234 -b[1];
	out[2]=a[2]+TWO_P1234 -b[2];
	out[3]=a[3]+TWO_P1234 -b[3];
	out[4]=a[4]+TWO_P1234 -b[4];
}
__device__ __forceinline__ void fe_sub_after_basic(fe out, const fe a, const fe b) {
	out[0]=a[0]+FOUR_P0    -b[0];
	out[1]=a[1]+FOUR_P1234 -b[1];
	out[2]=a[2]+FOUR_P1234 -b[2];
	out[3]=a[3]+FOUR_P1234 -b[3];
	out[4]=a[4]+FOUR_P1234 -b[4];
}
__device__ __forceinline__ void fe_sub_reduce(fe out, const fe a, const fe b) {
	uint64_t c;
	out[0]=a[0]+FOUR_P0    -b[0]    ; c=out[0]>>51; out[0]&=MASK51;
	out[1]=a[1]+FOUR_P1234 -b[1]+c  ; c=out[1]>>51; out[1]&=MASK51;
	out[2]=a[2]+FOUR_P1234 -b[2]+c  ; c=out[2]>>51; out[2]&=MASK51;
	out[3]=a[3]+FOUR_P1234 -b[3]+c  ; c=out[3]>>51; out[3]&=MASK51;
	out[4]=a[4]+FOUR_P1234 -b[4]+c  ; c=out[4]>>51; out[4]&=MASK51;
	out[0] += c*19;
}
__device__ __forceinline__ void fe_neg(fe out, const fe a) {
	uint64_t c;
	out[0]=TWO_P0    -a[0]    ; c=out[0]>>51; out[0]&=MASK51;
	out[1]=TWO_P1234 -a[1]+c  ; c=out[1]>>51; out[1]&=MASK51;
	out[2]=TWO_P1234 -a[2]+c  ; c=out[2]>>51; out[2]&=MASK51;
	out[3]=TWO_P1234 -a[3]+c  ; c=out[3]>>51; out[3]&=MASK51;
	out[4]=TWO_P1234 -a[4]+c  ; c=out[4]>>51; out[4]&=MASK51;
	out[0] += c*19;
}

__device__ __forceinline__ void fe_mul(fe out, const fe in2, const fe in) {
	u128 t[5], m;
	uint64_t r0,r1,r2,r3,r4,s0,s1,s2,s3,s4,c;

	r0=in[0]; r1=in[1]; r2=in[2]; r3=in[3]; r4=in[4];
	s0=in2[0]; s1=in2[1]; s2=in2[2]; s3=in2[3]; s4=in2[4];

	t[0] = mul64x64_128(r0, s0);
	t[1] = mul64x64_128(r0, s1); m = mul64x64_128(r1, s0); add128(t[1], m);
	t[2] = mul64x64_128(r0, s2); m = mul64x64_128(r2, s0); add128(t[2], m); m = mul64x64_128(r1, s1); add128(t[2], m);
	t[3] = mul64x64_128(r0, s3); m = mul64x64_128(r3, s0); add128(t[3], m); m = mul64x64_128(r1, s2); add128(t[3], m); m = mul64x64_128(r2, s1); add128(t[3], m);
	t[4] = mul64x64_128(r0, s4); m = mul64x64_128(r4, s0); add128(t[4], m); m = mul64x64_128(r3, s1); add128(t[4], m); m = mul64x64_128(r1, s3); add128(t[4], m); m = mul64x64_128(r2, s2); add128(t[4], m);

	r1*=19; r2*=19; r3*=19; r4*=19;

	m = mul64x64_128(r4, s1); add128(t[0], m); m = mul64x64_128(r1, s4); add128(t[0], m); m = mul64x64_128(r2, s3); add128(t[0], m); m = mul64x64_128(r3, s2); add128(t[0], m);
	m = mul64x64_128(r4, s2); add128(t[1], m); m = mul64x64_128(r2, s4); add128(t[1], m); m = mul64x64_128(r3, s3); add128(t[1], m);
	m = mul64x64_128(r4, s3); add128(t[2], m); m = mul64x64_128(r3, s4); add128(t[2], m);
	m = mul64x64_128(r4, s4); add128(t[3], m);

	r0 = lo128(t[0]) & MASK51; c = shr128(t[0], 51);
	add128_64(t[1], c); r1 = lo128(t[1]) & MASK51; c = shr128(t[1], 51);
	add128_64(t[2], c); r2 = lo128(t[2]) & MASK51; c = shr128(t[2], 51);
	add128_64(t[3], c); r3 = lo128(t[3]) & MASK51; c = shr128(t[3], 51);
	add128_64(t[4], c); r4 = lo128(t[4]) & MASK51; c = shr128(t[4], 51);
	r0 += c*19; c = r0>>51; r0 &= MASK51; r1 += c;

	out[0]=r0; out[1]=r1; out[2]=r2; out[3]=r3; out[4]=r4;
}

__device__ __noinline__ void fe_mul_noinline(fe out, const fe in2, const fe in) {
	fe_mul(out, in2, in);
}

__device__ __forceinline__ void fe_square(fe out, const fe in) {
	u128 t[5], m;
	uint64_t r0,r1,r2,r3,r4,c;
	uint64_t d0,d1,d2,d4,d419;

	r0=in[0]; r1=in[1]; r2=in[2]; r3=in[3]; r4=in[4];

	d0 = r0*2;
	d1 = r1*2;
	d2 = r2*2*19;
	d419 = r4*19;
	d4 = d419*2;

	t[0] = mul64x64_128(r0, r0); m = mul64x64_128(d4, r1); add128(t[0], m); m = mul64x64_128(d2, r3); add128(t[0], m);
	t[1] = mul64x64_128(d0, r1); m = mul64x64_128(d4, r2); add128(t[1], m); m = mul64x64_128(r3, r3*19); add128(t[1], m);
	t[2] = mul64x64_128(d0, r2); m = mul64x64_128(r1, r1); add128(t[2], m); m = mul64x64_128(d4, r3); add128(t[2], m);
	t[3] = mul64x64_128(d0, r3); m = mul64x64_128(d1, r2); add128(t[3], m); m = mul64x64_128(r4, d419); add128(t[3], m);
	t[4] = mul64x64_128(d0, r4); m = mul64x64_128(d1, r3); add128(t[4], m); m = mul64x64_128(r2, r2); add128(t[4], m);

	r0 = lo128(t[0]) & MASK51; c = shr128(t[0], 51);
	add128_64(t[1], c); r1 = lo128(t[1]) & MASK51; c = shr128(t[1], 51);
	add128_64(t[2], c); r2 = lo128(t[2]) & MASK51; c = shr128(t[2], 51);
	add128_64(t[3], c); r3 = lo128(t[3]) & MASK51; c = shr128(t[3], 51);
	add128_64(t[4], c); r4 = lo128(t[4]) & MASK51; c = shr128(t[4], 51);
	r0 += c*19; c = r0>>51; r0 &= MASK51; r1 += c;

	out[0]=r0; out[1]=r1; out[2]=r2; out[3]=r3; out[4]=r4;
}

__device__ __noinline__ void fe_square_times(fe out, const fe in, uint64_t count) {
	u128 t[5], m;
	uint64_t r0,r1,r2,r3,r4,c;
	uint64_t d0,d1,d2,d4,d419;

	r0=in[0]; r1=in[1]; r2=in[2]; r3=in[3]; r4=in[4];

	do {
		d0 = r0*2;
		d1 = r1*2;
		d2 = r2*2*19;
		d419 = r4*19;
		d4 = d419*2;

		t[0] = mul64x64_128(r0, r0); m = mul64x64_128(d4, r1); add128(t[0], m); m = mul64x64_128(d2, r3); add128(t[0], m);
		t[1] = mul64x64_128(d0, r1); m = mul64x64_128(d4, r2); add128(t[1], m); m = mul64x64_128(r3, r3*19); add128(t[1], m);
		t[2] = mul64x64_128(d0, r2); m = mul64x64_128(r1, r1); add128(t[2], m); m = mul64x64_128(d4, r3); add128(t[2], m);
		t[3] = mul64x64_128(d0, r3); m = mul64x64_128(d1, r2); add128(t[3], m); m = mul64x64_128(r4, d419); add128(t[3], m);
		t[4] = mul64x64_128(d0, r4); m = mul64x64_128(d1, r3); add128(t[4], m); m = mul64x64_128(r2, r2); add128(t[4], m);


		r0 = lo128(t[0]) & MASK51; c = shr128(t[0], 51);
		add128_64(t[1], c); r1 = lo128(t[1]) & MASK51; c = shr128(t[1], 51);
		add128_64(t[2], c); r2 = lo128(t[2]) & MASK51; c = shr128(t[2], 51);
		add128_64(t[3], c); r3 = lo128(t[3]) & MASK51; c = shr128(t[3], 51);
		add128_64(t[4], c); r4 = lo128(t[4]) & MASK51; c = shr128(t[4], 51);
		r0 += c*19; c = r0>>51; r0 &= MASK51; r1 += c;
	} while(--count);

	out[0]=r0; out[1]=r1; out[2]=r2; out[3]=r3; out[4]=r4;
}

__device__ __forceinline__ void fe_expand(fe out, const uint8_t *in) {
	uint64_t x0 = (uint64_t)in[0] | ((uint64_t)in[1]<<8) | ((uint64_t)in[2]<<16) | ((uint64_t)in[3]<<24)
	            | ((uint64_t)in[4]<<32) | ((uint64_t)in[5]<<40) | ((uint64_t)in[6]<<48) | ((uint64_t)in[7]<<56);
	uint64_t x1 = (uint64_t)in[8] | ((uint64_t)in[9]<<8) | ((uint64_t)in[10]<<16) | ((uint64_t)in[11]<<24)
	            | ((uint64_t)in[12]<<32) | ((uint64_t)in[13]<<40) | ((uint64_t)in[14]<<48) | ((uint64_t)in[15]<<56);
	uint64_t x2 = (uint64_t)in[16] | ((uint64_t)in[17]<<8) | ((uint64_t)in[18]<<16) | ((uint64_t)in[19]<<24)
	            | ((uint64_t)in[20]<<32) | ((uint64_t)in[21]<<40) | ((uint64_t)in[22]<<48) | ((uint64_t)in[23]<<56);
	uint64_t x3 = (uint64_t)in[24] | ((uint64_t)in[25]<<8) | ((uint64_t)in[26]<<16) | ((uint64_t)in[27]<<24)
	            | ((uint64_t)in[28]<<32) | ((uint64_t)in[29]<<40) | ((uint64_t)in[30]<<48) | ((uint64_t)in[31]<<56);
	out[0] = x0 & MASK51; x0 = (x0>>51) | (x1<<13);
	out[1] = x0 & MASK51; x1 = (x1>>38) | (x2<<26);
	out[2] = x1 & MASK51; x2 = (x2>>25) | (x3<<39);
	out[3] = x2 & MASK51; x3 = (x3>>12);
	out[4] = x3 & MASK51;
}

__device__ __forceinline__ void fe_contract(uint8_t *out, const fe input) {
	uint64_t t[5], f, i;
	t[0]=input[0]; t[1]=input[1]; t[2]=input[2]; t[3]=input[3]; t[4]=input[4];

#define CARRY() \
	t[1] += t[0]>>51; t[0] &= MASK51; \
	t[2] += t[1]>>51; t[1] &= MASK51; \
	t[3] += t[2]>>51; t[2] &= MASK51; \
	t[4] += t[3]>>51; t[3] &= MASK51;
#define CARRY_FULL() CARRY() t[0] += 19*(t[4]>>51); t[4] &= MASK51;
#define CARRY_FINAL() CARRY() t[4] &= MASK51;

	CARRY_FULL()
	CARRY_FULL()
	t[0] += 19;
	CARRY_FULL()
	t[0] += (MASK51+1)-19;
	t[1] += (MASK51+1)-1;
	t[2] += (MASK51+1)-1;
	t[3] += (MASK51+1)-1;
	t[4] += (MASK51+1)-1;
	CARRY_FINAL()

#define W51(n,shift) \
	f = ((t[n]>>shift) | (t[n+1]<<(51-shift))); \
	for (i = 0; i < 8; i++, f >>= 8) *out++ = (uint8_t)f;
	W51(0,0) W51(1,13) W51(2,26) W51(3,39)
#undef CARRY
#undef CARRY_FULL
#undef CARRY_FINAL
#undef W51
}

__device__ __noinline__ void fe_pow_two5mtwo0_two250mtwo0(fe b) {
	fe t0, c;
	fe_square_times(t0, b, 5);
	fe_mul_noinline(b, t0, b);
	fe_square_times(t0, b, 10);
	fe_mul_noinline(c, t0, b);
	fe_square_times(t0, c, 20);
	fe_mul_noinline(t0, t0, c);
	fe_square_times(t0, t0, 10);
	fe_mul_noinline(b, t0, b);
	fe_square_times(t0, b, 50);
	fe_mul_noinline(c, t0, b);
	fe_square_times(t0, c, 100);
	fe_mul_noinline(t0, t0, c);
	fe_square_times(t0, t0, 50);
	fe_mul_noinline(b, t0, b);
}

__device__ __noinline__ void fe_recip(fe out, const fe z) {
	fe a, t0, b;
	fe_square_times(a, z, 1);
	fe_square_times(t0, a, 2);
	fe_mul_noinline(b, t0, z);
	fe_mul_noinline(a, b, a);
	fe_square_times(t0, a, 1);
	fe_mul_noinline(b, t0, b);
	fe_pow_two5mtwo0_two250mtwo0(b);
	fe_square_times(b, b, 5);
	fe_mul_noinline(out, b, a);
}

__device__ __forceinline__ void fe_setone(fe out) {
	out[0]=1; out[1]=0; out[2]=0; out[3]=0; out[4]=0;
}

#define MODM_M0 ((uint64_t)0x12631a5cf5d3ed)
#define MODM_M1 ((uint64_t)0xf9dea2f79cd658)
#define MODM_M2 ((uint64_t)0x000000000014de)
#define MODM_M3 ((uint64_t)0x00000000000000)
#define MODM_M4 ((uint64_t)0x00000010000000)

#define MODM_MU0 ((uint64_t)0x9ce5a30a2c131b)
#define MODM_MU1 ((uint64_t)0x215d086329a7ed)
#define MODM_MU2 ((uint64_t)0xffffffffeb2106)
#define MODM_MU3 ((uint64_t)0xffffffffffffff)
#define MODM_MU4 ((uint64_t)0x00000fffffffff)

typedef uint64_t scalar[5];

__device__ __forceinline__ uint64_t lt_modm(uint64_t a, uint64_t b) {
	return (a - b) >> 63;
}

__device__ __noinline__ void reduce256_modm(scalar r) {
	scalar t;
	uint64_t b, pb, mask;
	pb = 0;
	pb += MODM_M0; b = lt_modm(r[0], pb); t[0] = (r[0]-pb+(b<<56)); pb = b;
	pb += MODM_M1; b = lt_modm(r[1], pb); t[1] = (r[1]-pb+(b<<56)); pb = b;
	pb += MODM_M2; b = lt_modm(r[2], pb); t[2] = (r[2]-pb+(b<<56)); pb = b;
	pb += MODM_M3; b = lt_modm(r[3], pb); t[3] = (r[3]-pb+(b<<56)); pb = b;
	pb += MODM_M4; b = lt_modm(r[4], pb); t[4] = (r[4]-pb+(b<<32));
	mask = b - 1;
	r[0] ^= mask & (r[0] ^ t[0]);
	r[1] ^= mask & (r[1] ^ t[1]);
	r[2] ^= mask & (r[2] ^ t[2]);
	r[3] ^= mask & (r[3] ^ t[3]);
	r[4] ^= mask & (r[4] ^ t[4]);
}

__device__ __noinline__ void barrett_reduce256_modm(scalar r, const scalar q1, const scalar r1) {
	scalar q3, r2;
	u128 c, mul;
	uint64_t f, b, pb;

	c = mul64x64_128(MODM_MU0, q1[3]); mul = mul64x64_128(MODM_MU3, q1[0]); add128(c, mul); mul = mul64x64_128(MODM_MU1, q1[2]); add128(c, mul); mul = mul64x64_128(MODM_MU2, q1[1]); add128(c, mul); f = shr128(c, 56);
	c = mul64x64_128(MODM_MU0, q1[4]); add128_64(c, f); mul = mul64x64_128(MODM_MU4, q1[0]); add128(c, mul); mul = mul64x64_128(MODM_MU3, q1[1]); add128(c, mul); mul = mul64x64_128(MODM_MU1, q1[3]); add128(c, mul); mul = mul64x64_128(MODM_MU2, q1[2]); add128(c, mul);
	f = lo128(c); q3[0] = (f>>40)&0xffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_MU4, q1[1]); add128_64(c, f); mul = mul64x64_128(MODM_MU1, q1[4]); add128(c, mul); mul = mul64x64_128(MODM_MU2, q1[3]); add128(c, mul); mul = mul64x64_128(MODM_MU3, q1[2]); add128(c, mul);
	f = lo128(c); q3[0] |= (f<<16)&0xffffffffffffff; q3[1] = (f>>40)&0xffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_MU4, q1[2]); add128_64(c, f); mul = mul64x64_128(MODM_MU2, q1[4]); add128(c, mul); mul = mul64x64_128(MODM_MU3, q1[3]); add128(c, mul);
	f = lo128(c); q3[1] |= (f<<16)&0xffffffffffffff; q3[2] = (f>>40)&0xffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_MU4, q1[3]); add128_64(c, f); mul = mul64x64_128(MODM_MU3, q1[4]); add128(c, mul);
	f = lo128(c); q3[2] |= (f<<16)&0xffffffffffffff; q3[3] = (f>>40)&0xffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_MU4, q1[4]); add128_64(c, f);
	f = lo128(c); q3[3] |= (f<<16)&0xffffffffffffff; q3[4] = (f>>40)&0xffff; f = shr128(c, 56);
	q3[4] |= (f<<16);

	c = mul64x64_128(MODM_M0, q3[0]);
	r2[0] = lo128(c) & 0xffffffffffffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_M0, q3[1]); add128_64(c, f); mul = mul64x64_128(MODM_M1, q3[0]); add128(c, mul);
	r2[1] = lo128(c) & 0xffffffffffffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_M0, q3[2]); add128_64(c, f); mul = mul64x64_128(MODM_M2, q3[0]); add128(c, mul); mul = mul64x64_128(MODM_M1, q3[1]); add128(c, mul);
	r2[2] = lo128(c) & 0xffffffffffffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_M0, q3[3]); add128_64(c, f); mul = mul64x64_128(MODM_M3, q3[0]); add128(c, mul); mul = mul64x64_128(MODM_M1, q3[2]); add128(c, mul); mul = mul64x64_128(MODM_M2, q3[1]); add128(c, mul);
	r2[3] = lo128(c) & 0xffffffffffffff; f = shr128(c, 56);
	c = mul64x64_128(MODM_M0, q3[4]); add128_64(c, f); mul = mul64x64_128(MODM_M4, q3[0]); add128(c, mul); mul = mul64x64_128(MODM_M3, q3[1]); add128(c, mul); mul = mul64x64_128(MODM_M1, q3[3]); add128(c, mul); mul = mul64x64_128(MODM_M2, q3[2]); add128(c, mul);
	r2[4] = lo128(c) & 0x0000ffffffffff;

	pb = 0;
	pb += r2[0]; b = lt_modm(r1[0], pb); r[0] = (r1[0]-pb+(b<<56)); pb = b;
	pb += r2[1]; b = lt_modm(r1[1], pb); r[1] = (r1[1]-pb+(b<<56)); pb = b;
	pb += r2[2]; b = lt_modm(r1[2], pb); r[2] = (r1[2]-pb+(b<<56)); pb = b;
	pb += r2[3]; b = lt_modm(r1[3], pb); r[3] = (r1[3]-pb+(b<<56)); pb = b;
	pb += r2[4]; b = lt_modm(r1[4], pb); r[4] = (r1[4]-pb+(b<<40));

	reduce256_modm(r);
	reduce256_modm(r);
}

__device__ __noinline__ void expand256_modm(scalar out, const uint8_t *in) {
	uint64_t x[8];
	for (int i = 0; i < 8; i++) {
		x[i] = (uint64_t)in[i*8+0] | ((uint64_t)in[i*8+1]<<8) | ((uint64_t)in[i*8+2]<<16) | ((uint64_t)in[i*8+3]<<24)
		     | ((uint64_t)in[i*8+4]<<32) | ((uint64_t)in[i*8+5]<<40) | ((uint64_t)in[i*8+6]<<48) | ((uint64_t)in[i*8+7]<<56);
	}
	out[0] = (                         x[0]) & 0xffffffffffffff;
	out[1] = ((x[0]>>56) | (x[1]<< 8)) & 0xffffffffffffff;
	out[2] = ((x[1]>>48) | (x[2]<<16)) & 0xffffffffffffff;
	out[3] = ((x[2]>>40) | (x[3]<<24)) & 0xffffffffffffff;
	out[4] = ((x[3]>>32) | (x[4]<<32)) & 0x0000ffffffffff;

	scalar q1;
	q1[0] = ((x[3]>>56) | (x[4]<< 8)) & 0xffffffffffffff;
	q1[1] = ((x[4]>>48) | (x[5]<<16)) & 0xffffffffffffff;
	q1[2] = ((x[5]>>40) | (x[6]<<24)) & 0xffffffffffffff;
	q1[3] = ((x[6]>>32) | (x[7]<<24)) & 0xffffffffffffff;
	q1[4] = ((x[7]>>24)                );
	barrett_reduce256_modm(out, q1, out);
}

__device__ __noinline__ void contract256_window4_modm(signed char r[64], const scalar in) {
	char carry = 0;
	signed char *quads = r;
	for (int i = 0; i < 5; i++) {
		uint64_t v = in[i];
		uint64_t m = (i == 4) ? 8 : 14;
		for (uint64_t j = 0; j < m; j++) {
			*quads++ = (signed char)(v & 15);
			v >>= 4;
		}
	}
	for (int i = 0; i < 63; i++) {
		r[i] += carry;
		r[i+1] += (r[i] >> 4);
		r[i] &= 15;
		carry = (r[i] >> 3);
		r[i] -= (carry << 4);
	}
	r[63] += carry;
}

typedef struct { fe x, y, z, t; } ge25519;
typedef struct { fe x, y, z, t; } ge25519_p1p1;
typedef struct { fe ysubx, xaddy, t2d; } ge25519_niels;
typedef struct { fe ysubx, xaddy, z, t2d; } ge25519_pniels;

__device__ __constant__ uint64_t GE_ECD[5] = {
	0x00034dca135978a3, 0x0001a8283b156ebd, 0x0005e7a26001c029, 0x000739c663a03cbb, 0x00052036cee2b6ff
};

__device__ __forceinline__ void ge_p1p1_to_full(ge25519 *r, const ge25519_p1p1 *p) {
	fe_mul(r->x, p->x, p->t);
	fe_mul(r->y, p->y, p->z);
	fe_mul(r->z, p->z, p->t);
	fe_mul(r->t, p->x, p->y);
}

__device__ __forceinline__ void ge_pnielsadd_p1p1(ge25519_p1p1 *r, const ge25519 *p, const ge25519_pniels *q, unsigned char signbit) {
	fe a, b, c;
	fe_sub(a, p->y, p->x);
	fe_add(b, p->y, p->x);

	{
		fe tmp;
		if (signbit == 0) { fe_copy(tmp, q->ysubx); } else { fe_copy(tmp, q->xaddy); }
		fe_mul(a, a, tmp);
		if (signbit == 0) { fe_copy(tmp, q->xaddy); } else { fe_copy(tmp, q->ysubx); }
		fe_mul(r->x, b, tmp);
	}
	fe_add(r->y, r->x, a);
	fe_sub(r->x, r->x, a);
	fe_mul(c, p->t, q->t2d);
	fe_mul(r->t, p->z, q->z);
	fe_add_reduce(r->t, r->t, r->t);
	fe_copy(r->z, r->t);

	if (signbit == 0) {
		fe_add_after_basic(r->z, r->z, c);
		fe_sub_after_basic(r->t, r->t, c);
	} else {
		fe_add_after_basic(r->t, r->t, c);
		fe_sub_after_basic(r->z, r->z, c);
	}
}

__device__ __forceinline__ void ge_add(ge25519_p1p1 *r, const ge25519 *p, const ge25519_pniels *q) {
	ge_pnielsadd_p1p1(r, p, q, 0);
}

__device__ __noinline__ void ge_scalarmult_base_choose_niels(ge25519_niels *t, const uint8_t table[256][96], uint32_t pos, signed char b) {

	if (b == 0) {

		t->ysubx[0]=1; t->ysubx[1]=0; t->ysubx[2]=0; t->ysubx[3]=0; t->ysubx[4]=0;
		t->xaddy[0]=1; t->xaddy[1]=0; t->xaddy[2]=0; t->xaddy[3]=0; t->xaddy[4]=0;
		t->t2d[0]=0;   t->t2d[1]=0;   t->t2d[2]=0;   t->t2d[3]=0;   t->t2d[4]=0;
		return;
	}
	uint32_t sign = (uint32_t)((unsigned char)b >> 7);
	uint32_t mask = ~(sign - 1);
	uint32_t u = ((uint32_t)b + mask) ^ mask;
	uint8_t packed[96];
	uint32_t row = (pos * 8) + (u - 1);
	for (int i = 0; i < 96; i++) packed[i] = table[row][i];
	fe_expand(t->ysubx, packed + 0);
	fe_expand(t->xaddy, packed + 32);
	fe_expand(t->t2d, packed + 64);
	if (sign) {

		fe tmp; fe_copy(tmp, t->ysubx); fe_copy(t->ysubx, t->xaddy); fe_copy(t->xaddy, tmp);
		fe_neg(t->t2d, t->t2d);
	}
}

__device__ __noinline__ void ge_scalarmult_base_niels(ge25519 *r, const uint8_t basepoint_table[256][96], const scalar s) {
	signed char b[64];
	ge25519_niels t;
	contract256_window4_modm(b, s);

	ge_scalarmult_base_choose_niels(&t, basepoint_table, 0, b[1]);
	fe_sub_reduce(r->x, t.xaddy, t.ysubx);
	fe_add_reduce(r->y, t.xaddy, t.ysubx);
	r->z[0]=2; r->z[1]=0; r->z[2]=0; r->z[3]=0; r->z[4]=0;
	fe_copy(r->t, t.t2d);
	for (uint32_t i = 3; i < 64; i += 2) {
		ge_scalarmult_base_choose_niels(&t, basepoint_table, i/2, b[i]);

		fe a,bb,c,e,f,g,h;
		fe_sub(a, r->y, r->x);
		fe_add(bb, r->y, r->x);
		fe_mul(a, a, t.ysubx);
		fe_mul(e, bb, t.xaddy);
		fe_add(h, e, a);
		fe_sub(e, e, a);
		fe_mul(c, r->t, t.t2d);
		fe_add(f, r->z, r->z);
		fe_add_after_basic(g, f, c);
		fe_sub_after_basic(f, f, c);
		fe_mul(r->x, e, f);
		fe_mul(r->y, h, g);
		fe_mul(r->z, g, f);
		fe_mul(r->t, e, h);
	}

#define DOUBLE_PARTIAL() do { ge25519_p1p1 tp; fe aa,bb,cc; \
	fe_square(aa, r->x); fe_square(bb, r->y); fe_square(cc, r->z); \
	fe_add_reduce(cc, cc, cc); fe_add(tp.x, r->x, r->y); fe_square(tp.x, tp.x); \
	fe_add(tp.y, bb, aa); fe_sub(tp.z, bb, aa); fe_sub_after_basic(tp.x, tp.x, tp.y); \
	fe_sub_after_basic(tp.t, cc, tp.z); \
	fe_mul(r->x, tp.x, tp.t); fe_mul(r->y, tp.y, tp.z); fe_mul(r->z, tp.z, tp.t); } while(0)
	DOUBLE_PARTIAL();
	DOUBLE_PARTIAL();
	DOUBLE_PARTIAL();
#undef DOUBLE_PARTIAL

	{
		ge25519_p1p1 tp; fe aa,bb,cc;
		fe_square(aa, r->x); fe_square(bb, r->y); fe_square(cc, r->z);
		fe_add_reduce(cc, cc, cc); fe_add(tp.x, r->x, r->y); fe_square(tp.x, tp.x);
		fe_add(tp.y, bb, aa); fe_sub(tp.z, bb, aa); fe_sub_after_basic(tp.x, tp.x, tp.y);
		fe_sub_after_basic(tp.t, cc, tp.z);
		fe_mul(r->x, tp.x, tp.t); fe_mul(r->y, tp.y, tp.z); fe_mul(r->z, tp.z, tp.t);
		fe_mul(r->t, tp.x, tp.y);
	}
	ge_scalarmult_base_choose_niels(&t, basepoint_table, 0, b[0]);
	fe_mul(t.t2d, t.t2d, GE_ECD);

	{
		fe a,bb,c,e,f,g,h;
		fe_sub(a, r->y, r->x); fe_add(bb, r->y, r->x);
		fe_mul(a, a, t.ysubx); fe_mul(e, bb, t.xaddy);
		fe_add(h, e, a); fe_sub(e, e, a);
		fe_mul(c, r->t, t.t2d); fe_add(f, r->z, r->z);
		fe_add_after_basic(g, f, c); fe_sub_after_basic(f, f, c);
		fe_mul(r->x, e, f); fe_mul(r->y, h, g); fe_mul(r->z, g, f); fe_mul(r->t, e, h);
	}
	for (uint32_t i = 2; i < 64; i += 2) {
		ge_scalarmult_base_choose_niels(&t, basepoint_table, i/2, b[i]);
		fe a,bb,c,e,f,g,h;
		fe_sub(a, r->y, r->x); fe_add(bb, r->y, r->x);
		fe_mul(a, a, t.ysubx); fe_mul(e, bb, t.xaddy);
		fe_add(h, e, a); fe_sub(e, e, a);
		fe_mul(c, r->t, t.t2d); fe_add(f, r->z, r->z);
		fe_add_after_basic(g, f, c); fe_sub_after_basic(f, f, c);
		fe_mul(r->x, e, f); fe_mul(r->y, h, g); fe_mul(r->z, g, f); fe_mul(r->t, e, h);
	}
}

__device__ __noinline__ void ge_batch_invert_z(ge25519 *in, fe *tmp, size_t num) {
	fe acc, tmpacc;
	size_t i;
	fe_setone(acc);
	for (i = 0; i < num; ++i) {
		fe_copy(tmp[i], acc);
		fe_mul(acc, acc, in[i].z);
	}
	fe_recip(acc, acc);
	i = num;
	while (i--) {
		fe_mul(tmpacc, acc, in[i].z);
		fe_mul(in[i].z, acc, tmp[i]);
		fe_copy(acc, tmpacc);
	}
}

__device__ __noinline__ void ge_batchpack_destructive_1(uint8_t (*out)[32], ge25519 *in, fe *tmp, size_t num) {
	ge_batch_invert_z(in, tmp, num);
	for (size_t i = 0; i < num; ++i) {
		fe ty;
		fe_mul(ty, in[i].y, in[i].z);
		fe_contract(out[i], ty);
	}
}

__device__ __forceinline__ void ge_batchpack_destructive_finish(uint8_t out[32], ge25519 *unf) {
	fe tx;
	uint8_t parity[32];
	fe_mul(tx, unf->x, unf->z);
	fe_contract(parity, tx);
	out[31] ^= ((parity[0] & 1) << 7);
}

#endif
