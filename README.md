# ik_llama.cpp-zen5

This is a heavily customized Arch Linux PKGBUILD for `ik_llama.cpp`, specifically optimized for the AMD Ryzen 9 9950X (Zen 5) processor and modern NVIDIA GPUs (RTX 30 series and higher).

## Optimizations

- **Modern GPU Targeting**: Compiles CUDA binaries strictly for `86;89;90` architectures (Ampere, Ada Lovelace, Hopper), reducing binary bloat and stripping out legacy support.
- **Aggressive CPU Tuning**: Forcibly overrides compiler flags with `-O3 -march=native -mtune=native` to take absolute advantage of the Zen 5 pipeline.
- **AVX-512**: Fully utilizes Zen 5's 512-bit wide data paths with enabled `AVX512`, `VBMI`, `VNNI`, and `BF16` extensions.
- **LTO**: Link-Time Optimization is enabled for maximal cross-module tuning.

## Usage

Simply run `makepkg -si` to build and install the package on your target machine.

**Note**: This is a highly specialized build configuration. It will compile natively for whatever CPU you build it on (so ensure you build it on the 9950X!) and is restricted to RTX 30+ GPUs.
