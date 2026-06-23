# AGENTS.md

Compact guidance for OpenCode sessions working in this repo.

## What this is

`mkp224o` — a brute-force vanity address generator for Tor v3 (ed25519) onion services. This fork adds an **optional CUDA GPU worker** (selected at runtime with `--cuda`); without `--enable-cuda` at configure time and `--cuda` at runtime, it behaves identically to upstream `cathugger/mkp224o` (CPU-only). The directory is named `mkp224o-cuda` for this reason.

## Build (autotools — non-obvious)

Hard deps: **libsodium** (headers + lib), C99 compiler, GNU make, POSIX (pthreads). `configure.ac` intentionally does NOT check for libsodium (see comment near configure.ac:44), so a missing libsodium surfaces as compile errors, not a configure failure — don't waste time looking for the check.

```
./autogen.sh && ./configure && make
```

- `autogen.sh` just runs `autoconf -f` to generate `configure`. Required on a fresh checkout because `configure` and `GNUmakefile` are gitignored (only `GNUmakefile.in` + `configure.ac` are tracked). Release tarballs ship a prebuilt `configure`.
- The generated makefile is `GNUmakefile` (GNU make required), not `Makefile` — `make` will fail with "No targets" before configure is run.
- **Reconfiguring requires `make clean` first.** Configure options and CFLAGS/LDFLAGS do not carry over between runs; re-specify every flag.
- On *BSD use `gmake`, and may need `./configure CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib"`.
- On AMD64 you usually want `--enable-amd64-51-30k` for speed (see `OPTIMISATION.txt`).

Targets: `make` (= mkp224o only) · `make all` (mkp224o + calcest + tests) · `make util` (calcest) · `make test` (builds tests, does NOT run them) · `make clean` / `make distclean` (distclean also deletes `configure` + `GNUmakefile`).

## Configure-time feature selection (compile-time, NOT runtime)

ed25519 implementation is **mutually exclusive**, chosen at configure: `--enable-ref10` (portable C, old default) · `--enable-donna` (current default) · `--enable-donna-sse2` (x86+SSE2) · `--enable-amd64-51-30k` / `--enable-amd64-64-24k` (x86_64 only). See `./configure --help` and `OPTIMISATION.txt`.

Other compile-time flags — toggling any requires reconfigure + `make clean` + `make`:
- `--enable-intfilter[=32|64|128|native]` — integer filters, faster but caps filter length (6/12/24 chars); default off = binary strings, unlimited length.
- `--enable-binsearch` — binary-search filters, faster with many filters (>100).
- `--enable-besort` — big-endian sort for intfilter+binsearch when filter lengths differ.
- `--enable-regex` / `--with-pcre2` — PCRE2 regex filters (needs `pcre2-config`).
- `--enable-batchnum=N` — batch element count (default 2048); batch mode is the experimental `-B` runtime flag, ~15x faster.
- `--enable-statistics` (default on) — enables `-s` runtime stats.
- Passphrase mode (`-p`) is auto-enabled if libsodium supports ARGON2ID13 (detected in configure.ac, defines `PASSPHRASE`).
- `--enable-cuda` — build the optional CUDA GPU worker (`cuda_worker.cu` via `nvcc`). Adds `--cuda` at runtime. Requires the CUDA toolkit (`nvcc` in PATH). Tunables: `--enable-cuda-batchnum=N` (keys per GPU-thread batch, default 64), `--enable-cuda-tpb=N` (threads/block, default 64), `--enable-cuda-arch=flag` (nvcc `-arch`, default `native`). **Windows/MSYS2**: nvcc defaults to MSVC as host compiler, which mismatches the mingw ABI used by the rest of the build — pass `./configure NVCC='nvcc -ccbin /mingw64/bin/gcc' --enable-cuda` so nvcc uses mingw gcc. On Linux this just works.

The selected ed25519 impl is baked in via `-DED25519_<impl>` plus `CRYPTO_NAMESPACE` macros (see per-object CFLAGS in `GNUmakefile.in`) that prefix every symbol so the four impls coexist in one tree. **Do not break this namespacing when editing `ed25519/`** or builds fail with duplicate-symbol errors.

## CUDA worker (`--enable-cuda` + runtime `--cuda`)

When `--cuda` is passed, `main.c` calls `cuda_worker_run()` (in `cuda_worker.cu`) instead of spawning CPU pthreads. Each CUDA thread runs the same batch key-derivation loop as the CPU `worker_batch()`: random scalar → `ge_scalarmult_base` → add-chain with the precomputed `8*B` point → batch-invert → pack → prefix-filter. Matches are pushed to a device queue; the host drains it (every ~500ms or when the queue fills) and finishes each key via `worker_finish_match()` in `worker.c`, which reuses the **same `onionready()` path as the CPU worker** (so output files/checksums/base32 are identical).

- Device ed25519 arithmetic is a faithful port of donna's 5×51-bit radix field ops to CUDA (`cuda_ed25519.cuh`), with `__int128` emulated via `__umul64hi`. It reuses the **exact upstream basepoint table** (`ed25519/ed25519-donna/ed25519-donna-basepoint-table.h`) uploaded to `__constant__` memory, and the exact `8*B` pniels bytes from `ed25519_impl_pre.h`. Correctness was verified on-GPU: `scalarmult_base(1)`→base point, `B + eightpoint == 9*B`, and an end-to-end prefix-mining test.
- **Limitations of `--cuda` (v1)**: no passphrase mode (`-p`/`-P`), no multi-word filters (`-N>1`), no PCRE2 regex filters — `main.c` errors out if combined with `--cuda`. The device filter is a plain byte-prefix scan (works for both `--enable-intfilter` and default binary-string filters). `-n N` with a very short prefix can overshoot (the GPU finds many matches within one batch before re-checking the stop flag); for realistic rare prefixes overshoot is negligible.
- `-t`/`-j` are ignored in `--cuda` mode (GPU grid sized automatically via `cudaOccupancyMaxActiveBlocksPerMultiprocessor`). `-s`/`-S` stats work (the host prints `calc/sec` from a device atomic counter).

## Tests

`make test` builds four standalone assert-based programs: `test_base16`, `test_base32`, `test_base64`, `test_ed25519`. There is **no test runner and no `make check`** — run each binary manually; exit code 0 = pass, `assert()` aborts on failure. `test_ed25519` links libsodium. `testutil.h` only provides `WARN`/`WARNF` macros; most checks use raw `assert()`.

Verification loop when changing code:
```
./autogen.sh && ./configure && make && make test && ./test_base16 && ./test_base32 && ./test_base64 && ./test_ed25519
```
If you changed configure flags, run `make clean` first.

## Repo layout

- Root `*.c`/`*.h` = the project's own code (main, worker, filters, base16/32/64, keccak, yaml, ioutil, vec, cpucount, calcest).
- `ed25519/{ref10,amd64-51-30k,amd64-64-24k,ed25519-donna}/` = **vendored reference implementations** adopted from SUPERCOP / floodyberry. Treat as third-party; generally do not edit.
- `worker_impl.inc.h`, `worker_batch*.inc.h`, `filters_*.inc.h` are `.inc.h` headers `#include`d into `worker.c` / `main.c` — they are real executable code, not documentation.
- `contrib/` = Docker, Vagrant, release scripts. `contrib/docker/Dockerfile` is the canonical CI build (`--enable-amd64-51-30k`, static linking).
- `cuda_worker.cu` + `cuda_ed25519.cuh` + `cuda_worker.h` = the optional CUDA GPU worker (only compiled with `--enable-cuda`).
- Dependency lines after `# DO NOT DELETE THIS LINE` in `GNUmakefile.in` are maintained by `make depend` (needs `makedepend` from imake). Regenerate when adding/changing headers.

## CI

`.github/workflows/docker-publish.yml` only builds and publishes the Docker image to `ghcr.io/cathugger/mkp224o` on push/PR to master. **There is no compile or test CI** — local `make` + `make test` is the only verification gate.

## Style

Per `.editorconfig`: **tabs** for root `*.c`/`*.h`, `GNUmakefile.in`, `configure.ac`; **2-space** for `ed25519/{ref10,amd64-51-30k,amd64-64-24k}/*`. LF endings, trim trailing whitespace, final newline. Match per-directory style when editing.

## Runtime gotchas (when running the built tool)

`mkp224o` writes a directory per discovered key into the working dir (override with `-d`), so a run can litter the tree with `*.onion` directories (gitignored). Onion addresses are base32 — digits `0,1,8,9` are invalid and rejected as filters. `-s` prints stats, `-B` enables batch mode, `-h` lists all flags.
