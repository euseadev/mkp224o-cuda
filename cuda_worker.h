
#ifndef CUDA_WORKER_H
#define CUDA_WORKER_H

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef CUDA_ENABLE

int cuda_available(void);

void cuda_set_filters(void);

void worker_finish_match(const u8 *a0, const u8 *secondhalf, const u8 *pk, u32 b);

void cuda_upload_filters(const unsigned char *fm, size_t count);

void cuda_worker_run(u64 reportdelay_us, int realtimestats);

#endif

#ifdef __cplusplus
}
#endif

#endif
