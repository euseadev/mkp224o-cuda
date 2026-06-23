# mkp224o-cuda

GPU-accelerated vanity address generator for Tor v3 (ed25519) onion services — a CUDA fork of [cathugger/mkp224o](https://github.com/cathugger/mkp224o).

Adds an optional `--cuda` GPU worker that runs the same batch key-derivation loop as the CPU mode but on NVIDIA GPUs. Without `--cuda`, behaviour is identical to upstream.

## Requirements

- C99 compiler, GNU make, autoconf
- **libsodium** (headers + library)
- **CUDA toolkit** (`nvcc` in PATH) — optional, only when building with `--enable-cuda`
- POSIX platform (Linux, OpenBSD, msys2/cygwin)

**Debian/Ubuntu:**
```bash
apt install gcc libc6-dev libsodium-dev make autoconf
```

## Build

```bash
./autogen.sh
./configure --enable-amd64-51-30k --enable-cuda
make
```

For fastest CPU performance add `--enable-amd64-51-30k` on x86_64 (see `OPTIMISATION.txt`).  
**Windows/MSYS2:** nvcc defaults to MSVC as host compiler — pass mingw gcc explicitly:
```bash
./configure NVCC='nvcc -ccbin /mingw64/bin/gcc' --enable-cuda
make
```

Tunable CUDA options (`./configure --help` for full list):
- `--enable-cuda-batchnum=N` — keys per GPU-thread batch (default 64)
- `--enable-cuda-tpb=N` — threads per block (default 64)
- `--enable-cuda-arch=ARCH` — nvcc `-arch` flag (default `native`)

## Usage

```
mkp224o --cuda [-d outputdir] [-n numkeys] [-s] filter
```

GPU mode (`--cuda`):
```bash
./mkp224o --cuda -s -d keys openarch
```

CPU mode (identical to upstream):
```bash
./mkp224o -d keys openarch
```

## GPU vs CPU

| | GPU `--cuda` | CPU |
|---|---|---|
| Key derivation | CUDA kernel (cuRAND) | pthread workers (libsodium random) |
| ed25519 | Ported donna 5x51-bit (cuda_ed25519.cuh) | Selected at configure time |
| Throughput (RTX 5060 Ti) | ~160M keys/s | ~2M keys/s/core |
| Passphrase `-p/-P` | Not supported | Supported |
| Multi-word `-N>1` | Not supported | Supported |
| Regex `--enable-regex` | Not supported | Supported |

## Output

Each discovered key creates a directory:
```
keys/
  openarchxxxx...onion/
    hostname
    hs_ed25519_secret_key
    hs_ed25519_public_key
```

Copy to Tor:
```bash
sudo cp -r openarchxxxx...onion /var/lib/tor/myservice
sudo chown -R tor: /var/lib/tor/myservice
```

Then add to `torrc` and reload Tor.

## Credits

Fork of [cathugger/mkp224o](https://github.com/cathugger/mkp224o) — all original CPU logic, ed25519 implementations, and the batch-mode horse25519 trick remain intact.

GPU ed25519 arithmetic ported from floodyberry's [ed25519-donna](https://github.com/floodyberry/ed25519-donna), reusing the exact upstream basepoint table.

Public domain (CC0). See `COPYING.txt`.
