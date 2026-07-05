FROM nvidia/cuda:13.3.0-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-14 \
    g++-14 \
    cmake \
    git \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the bleeding edge ik_llama.cpp
RUN git clone https://github.com/ikawrakow/ik_llama.cpp.git . && \
    sed -i 's/get_flags(${CUDA_CCID} ${CUDA_CCVER})/if(CUDA_CCVER)\nget_flags(${CUDA_CCID} ${CUDA_CCVER})\nelse()\nget_flags(${CUDA_CCID} 13.0.0)\nendif()/g' ggml/src/CMakeLists.txt && \
    sed -i 's/ggml_backend_cuda_init(device, nullptr)/ggml_backend_cuda_init(device, nullptr, nullptr)/g' examples/rpc/rpc-server.cpp

# Build with extreme optimizations (Zen 5 + RTX 30/40/50)
RUN cmake -B build -G Ninja \
    -DCMAKE_C_COMPILER=gcc-14 \
    -DCMAKE_CXX_COMPILER=g++-14 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_USE_SYSTEM_GGML=OFF \
    -DGGML_LTO=ON \
    -DGGML_RPC=ON \
    -DGGML_CUDA=ON \
    -DGGML_CUDA_FA_ALL_QUANTS=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_OPENSSL=ON \
    -DGGML_AVX512=ON \
    -DGGML_AVX512_VBMI=ON \
    -DGGML_AVX512_VNNI=ON \
    -DGGML_AVX512_BF16=ON \
    -DGGML_NATIVE=OFF \
    -DCMAKE_CUDA_ARCHITECTURES="86;89;90" \
    -DCMAKE_C_FLAGS="-O3 -march=znver5 -mtune=znver5" \
    -DCMAKE_CXX_FLAGS="-O3 -march=znver5 -mtune=znver5"

RUN cmake --build build --config Release -j $(nproc)

# Final runtime image
# (Using ubuntu24.04 base for the runtime to ensure rock-solid stability with latest CUDA)
FROM nvidia/cuda:13.3.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libssl3 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled binaries from builder
COPY --from=builder /app/build/bin/llama-server /usr/local/bin/
# Also copy llama-cli in case manual debugging is needed inside the container
COPY --from=builder /app/build/bin/llama-cli /usr/local/bin/

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default server port
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
