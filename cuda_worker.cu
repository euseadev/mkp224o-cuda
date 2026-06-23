
#ifndef CUDA_ENABLE

typedef int cuda_worker_disabled_not_compiled;
#else

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <chrono>
#include <thread>

#include <cuda_runtime.h>
#include <curand_kernel.h>

extern "C" {
#include "types.h"
#include "cuda_worker.h"

extern volatile int endwork;
extern volatile size_t keysgenerated;
extern size_t numneedgenerate;
extern void worker_finish_match(const u8 *a0, const u8 *secondhalf, const u8 *pk, u32 b);
}

#include "cuda_ed25519.cuh"

#define ALIGN(x)
#include "ed25519/ed25519-donna/ed25519-donna-basepoint-table.h"

#ifndef CUDA_BATCH
#define CUDA_BATCH 64
#endif
#ifndef CUDA_MAX_MATCHES
#define CUDA_MAX_MATCHES 1024
#endif
#ifndef CUDA_TPB
#define CUDA_TPB 64
#endif

__device__ __constant__ uint8_t d_bptable[256][96];

__device__ __constant__ uint8_t d_ep_ysubx[32] = {
	0xE0,0xC3,0x64,0xC7,0xDC,0xAD,0x36,0x5E,0x25,0xAA,0x86,0xC8,0xC7,0x85,0x5F,0x07,
	0x67,0x65,0x1C,0x3D,0x99,0xDD,0x26,0x55,0x9C,0xB5,0x71,0x1E,0x1D,0xC4,0xC8,0x71
};
__device__ __constant__ uint8_t d_ep_xaddy[32] = {
	0x9C,0xFD,0xE3,0xC2,0x2A,0x15,0x34,0x1B,0x3B,0xE7,0x62,0xAB,0x56,0xFA,0xDF,0xE7,
	0xCF,0xBE,0xB5,0x8D,0x83,0x8A,0x1D,0xA5,0xAD,0x3E,0x42,0x42,0xC9,0x4F,0x1B,0x09
};
__device__ __constant__ uint8_t d_ep_z[32] = {
	0x77,0xAA,0x7F,0x85,0x02,0x8E,0xF5,0xD9,0x52,0xFE,0x8F,0xE6,0x8A,0x52,0x21,0x4A,
	0xCB,0x8D,0x1C,0x05,0x7D,0xAD,0x4A,0x1B,0xC6,0x7B,0x23,0x9D,0x4C,0x3F,0xD6,0x02
};
__device__ __constant__ uint8_t d_ep_t2d[32] = {
	0x4E,0x06,0xF4,0xFB,0x04,0x0B,0xCE,0x86,0x6B,0x52,0xBB,0x96,0x0A,0xCE,0x11,0x3C,
	0xCD,0xEF,0x4A,0x46,0x68,0x47,0xAA,0x72,0x5F,0x65,0x90,0x91,0xA8,0x38,0xCA,0x37
};

__device__ uint8_t *d_filters = 0;
__device__ uint32_t d_nfilters = 0;

struct cuda_match {
	uint8_t a0[32];
	uint8_t secondhalf[32];
	uint8_t pk[32];
	uint32_t b;
};

__device__ cuda_match *d_matches = 0;
__device__ unsigned long long *d_nmatches = 0;
__device__ int *d_endwork = 0;
__device__ unsigned long long *d_numcalc = 0;
__device__ unsigned long long *d_remaining = 0;   

__device__ __forceinline__ bool filter_match(const uint8_t pk[32]) {
	uint32_t n = d_nfilters;
	for (uint32_t fi = 0; fi < n; fi++) {
		const uint8_t *f = d_filters + (size_t)fi * 64;
		const uint8_t *m = f + 32;
		bool ok = true;
		for (int i = 0; i < 32; i++) {
			if (m[i] && (pk[i] & m[i]) != f[i]) { ok = false; break; }
		}
		if (ok) return true;
	}
	return false;
}

__device__ __forceinline__ void fill_random(curandStateXORWOW_t *st, uint8_t *buf, int n) {
	for (int i = 0; i < n; i++)
		buf[i] = (uint8_t)(curand(st) & 0xFF);
}

__global__ void mine_kernel(unsigned long long seedoffset) {
	uint64_t tid = (uint64_t)blockIdx.x * blockDim.x + threadIdx.x;

	curandStateXORWOW_t st;
	curand_init((unsigned int)(7129 + seedoffset), (unsigned int)tid, 0, &st);


	ge25519_pniels ep;
	fe_expand(ep.ysubx, d_ep_ysubx);
	fe_expand(ep.xaddy, d_ep_xaddy);
	fe_expand(ep.z,     d_ep_z);
	fe_expand(ep.t2d,   d_ep_t2d);

	ge25519  ge_batch[CUDA_BATCH];
	fe       tmp_batch[CUDA_BATCH];
	uint8_t  pk_batch[CUDA_BATCH][32];

	while (!(*d_endwork)) {
		uint8_t a0[32], secondhalf[32];
		fill_random(&st, a0, 32);
		fill_random(&st, secondhalf, 32);

		a0[0] &= 248;
		a0[31] &= 127;
		a0[31] |= 64;

		scalar s;
		expand256_modm(s, a0);
		ge25519 P;
		ge_scalarmult_base_niels(&P, d_bptable, s);

		for (int b = 0; b < CUDA_BATCH; b++) {
			ge_batch[b] = P;
			ge25519_p1p1 sum;
			ge_add(&sum, &P, &ep);
			ge_p1p1_to_full(&P, &sum);
		}
		ge_batchpack_destructive_1(pk_batch, ge_batch, tmp_batch, CUDA_BATCH);
		atomicAdd(d_numcalc, (unsigned long long)CUDA_BATCH);

		for (int b = 0; b < CUDA_BATCH; b++) {
			if (filter_match(pk_batch[b])) {
				ge_batchpack_destructive_finish(pk_batch[b], &ge_batch[b]);
				unsigned long long idx = atomicAdd(d_nmatches, (unsigned long long)1);
				if (idx < (unsigned long long)CUDA_MAX_MATCHES) {
					cuda_match *dst = &d_matches[idx];
					for (int i = 0; i < 32; i++) dst->a0[i] = a0[i];
					for (int i = 0; i < 32; i++) dst->secondhalf[i] = secondhalf[i];
					for (int i = 0; i < 32; i++) dst->pk[i] = pk_batch[b][i];
					dst->b = (uint32_t)b;
				}

				if (atomicAdd(d_remaining, (unsigned long long)-1) <= 1)
					atomicExch(d_endwork, 1);

				if (idx >= (unsigned long long)(CUDA_MAX_MATCHES - 1))
					atomicExch(d_endwork, 1);

				goto next_seed;
			}
		}
	next_seed:
		;
	}
}

static int g_init_done = 0;
static cuda_match *g_hmatches = 0;
static unsigned long long g_seedoff = 0; 

static cuda_match  *gm_matches = 0;
static unsigned long long *gm_nmatches = 0;
static int          *gm_endwork = 0;
static unsigned long long *gm_numcalc = 0;
static unsigned long long *gm_remaining = 0;
static uint8_t      *gm_filters = 0;
static int           g_grid = 0, g_tpb = CUDA_TPB;

static int cuda_check(cudaError_t e, const char *what) {
	if (e != cudaSuccess) {
		fprintf(stderr, "CUDA error (%s): %s\n", what, cudaGetErrorString(e));
		return -1;
	}
	return 0;
}

static u64 now_us(void) {
	return (u64)std::chrono::duration_cast<std::chrono::microseconds>(
		std::chrono::steady_clock::now().time_since_epoch()).count();
}

static int dev_init(void) {
	if (g_init_done) return 0;

	int ndev = 0;
	if (cudaGetDeviceCount(&ndev) != cudaSuccess || ndev <= 0) {
		fprintf(stderr, "no CUDA-capable device found\n");
		return -1;
	}
	int dev = 0;

	for (int i = 0; i < ndev; i++) {
		cudaDeviceProp p;
		if (cudaGetDeviceProperties(&p, i) != cudaSuccess) continue;
		if (p.major >= 5) { dev = i; break; }
	}
	if (cudaSetDevice(dev) != cudaSuccess) {
		fprintf(stderr, "failed to select CUDA device\n");
		return -1;
	}
	cudaDeviceProp prop;
	cudaGetDeviceProperties(&prop, dev);
	if (!g_grid) {
		int maxb;
		if (cudaOccupancyMaxActiveBlocksPerMultiprocessor(&maxb, mine_kernel, g_tpb, 0) == cudaSuccess && maxb > 0) {
			g_grid = prop.multiProcessorCount * maxb;
		} else {
			g_grid = prop.multiProcessorCount * 8;
		}
	}

	if (cuda_check(cudaMalloc(&gm_matches, sizeof(cuda_match) * CUDA_MAX_MATCHES), "malloc matches")) return -1;
	if (cuda_check(cudaMalloc(&gm_nmatches, sizeof(unsigned long long)), "malloc nmatches")) return -1;
	if (cuda_check(cudaMalloc(&gm_endwork, sizeof(int)), "malloc endwork")) return -1;
	if (cuda_check(cudaMalloc(&gm_numcalc, sizeof(unsigned long long)), "malloc numcalc")) return -1;
	if (cuda_check(cudaMalloc(&gm_remaining, sizeof(unsigned long long)), "malloc remaining")) return -1;
	if (cuda_check(cudaMalloc(&gm_filters, 64 * 4096), "malloc filters")) return -1;


	cudaMemcpyToSymbol(d_matches,  &gm_matches,  sizeof(gm_matches));
	cudaMemcpyToSymbol(d_nmatches, &gm_nmatches, sizeof(gm_nmatches));
	cudaMemcpyToSymbol(d_endwork,  &gm_endwork,  sizeof(gm_endwork));
	cudaMemcpyToSymbol(d_numcalc,  &gm_numcalc,  sizeof(gm_numcalc));
	cudaMemcpyToSymbol(d_remaining,&gm_remaining,sizeof(gm_remaining));
	cudaMemcpyToSymbol(d_filters,  &gm_filters,  sizeof(gm_filters));


	cudaMemcpyToSymbol(d_bptable, ge25519_niels_base_multiples, sizeof(d_bptable));

	g_hmatches = (cuda_match *)malloc(sizeof(cuda_match) * CUDA_MAX_MATCHES);
	if (!g_hmatches) { fprintf(stderr, "out of memory\n"); return -1; }

	g_init_done = 1;
	return 0;
}

extern "C" int cuda_available(void) {
	int ndev = 0;
	if (cudaGetDeviceCount(&ndev) != cudaSuccess) return 0;
	return ndev > 0 ? 1 : 0;
}

extern "C" void cuda_upload_filters(const unsigned char *fm, size_t count) {
	if (dev_init() < 0) { fprintf(stderr, "CUDA init failed\n"); exit(1); }
	if (count > 4096) {
		fprintf(stderr, "too many filters for CUDA worker (max 4096), aborting\n");
		exit(1);
	}
	cudaMemcpy(gm_filters, fm, 64 * count, cudaMemcpyHostToDevice);
	cudaMemcpyToSymbol(d_nfilters, &count, sizeof(d_nfilters));
}

extern "C" void worker_finish_match(const u8 *a0, const u8 *secondhalf, const u8 *pk, u32 b);

static void drain_matches(unsigned long long nm) {
	if (nm > (unsigned long long)CUDA_MAX_MATCHES) nm = CUDA_MAX_MATCHES;
	if (nm == 0) return;
	cudaMemcpy(g_hmatches, gm_matches, sizeof(cuda_match) * nm, cudaMemcpyDeviceToHost);
	for (unsigned long long i = 0; i < nm; i++) {

		worker_finish_match(g_hmatches[i].a0, g_hmatches[i].secondhalf, g_hmatches[i].pk, g_hmatches[i].b);
	}
}

extern "C" void cuda_worker_run(u64 reportdelay_us, int realtimestats) {
	if (dev_init() < 0) { fprintf(stderr, "CUDA init failed\n"); exit(1); }

	cudaMemset(gm_nmatches, 0, sizeof(unsigned long long));
	cudaMemset(gm_endwork, 0, sizeof(int));
	cudaMemset(gm_numcalc, 0, sizeof(unsigned long long));

	unsigned long long rem = numneedgenerate ? (unsigned long long)numneedgenerate : 0xFFFFFFFFFFFFFFFFULL;
	cudaMemcpy(gm_remaining, &rem, sizeof(unsigned long long), cudaMemcpyHostToDevice);

	fprintf(stderr, "using CUDA: %d blocks x %d threads/block (%d threads)\n",
		g_grid, g_tpb, g_grid * g_tpb);

#ifdef STATISTICS
	u64 istarttime = now_us(), ireporttime = 0, elapsedoffset = 0, lastflush = istarttime;
#else
	u64 lastflush = now_us();
#endif


	g_seedoff = (unsigned long long)std::chrono::steady_clock::now().time_since_epoch().count();
	mine_kernel<<<g_grid, g_tpb>>>(g_seedoff);


	const u64 FLUSH_US = 500000;
	for (;;) {
		std::this_thread::sleep_for(std::chrono::milliseconds(50));

		int dev_end = 0;
		cudaMemcpy(&dev_end, gm_endwork, sizeof(int), cudaMemcpyDeviceToHost);
		u64 now = now_us();
		int force = (now - lastflush) >= FLUSH_US;

		if (dev_end || force || endwork) {

			if (!dev_end) {
				cudaMemset(gm_endwork, 1, sizeof(int));
				cudaDeviceSynchronize();
			} else {
				cudaDeviceSynchronize();
			}
			unsigned long long nm = 0;
			cudaMemcpy(&nm, gm_nmatches, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
			if (nm) drain_matches(nm);

#ifdef STATISTICS
			if (reportdelay_us && (!ireporttime || (i64)(now - ireporttime) >= (i64)reportdelay_us)) {
				if (ireporttime) ireporttime += reportdelay_us; else ireporttime = now;
				if (!ireporttime) ireporttime = 1;
				unsigned long long calc = 0;
				cudaMemcpy(&calc, gm_numcalc, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
				u64 succ = (u64)keysgenerated;
				double calcpersec = (1000000.0 * (double)calc) / (double)(now - istarttime);
				double succpersec = (1000000.0 * (double)succ) / (double)(now - istarttime);
				double restpersec = (1000000.0 * (double)(calc / CUDA_BATCH)) / (double)(now - istarttime);
				fprintf(stderr, ">calc/sec:%8lf, succ/sec:%8lf, rest/sec:%8lf, elapsed:%5.6lfsec\n",
					calcpersec, succpersec, restpersec,
					(now - istarttime + elapsedoffset) / 1000000.0);
				if (realtimestats) {
					elapsedoffset += now - istarttime;
					istarttime = now;
					cudaMemset(gm_numcalc, 0, sizeof(unsigned long long));
				}
			}
#endif

			if (endwork) break;


			cudaMemset(gm_nmatches, 0, sizeof(unsigned long long));
			cudaMemset(gm_endwork, 0, sizeof(int));
			g_seedoff++;
			mine_kernel<<<g_grid, g_tpb>>>(g_seedoff);
			lastflush = now_us();
#ifdef STATISTICS
			if (!reportdelay_us) {}
#endif
		}
	}

	cudaDeviceSynchronize();
	cudaMemset(gm_endwork, 0, sizeof(int));
	cudaMemset(gm_nmatches, 0, sizeof(unsigned long long));

	fprintf(stderr, "waiting for GPU to finish... done.\n");
}

#endif
