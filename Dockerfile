FROM docker.io/rocm/dev-ubuntu-24.04:7.2.4-complete


ARG LLAMA_CPP_REPO="https://github.com/ggml-org/llama.cpp.git"
ARG LLAMA_CPP_COMMIT="4c6595503fe45d5a39f88d194e270f64c7424677"

ARG LLAMA_SWAP_CHECKSUM="564137e5776c1fc60897e4a8de0f731ed06f3ea28eec02a1b31bdb0f24084e2e"
ARG LLAMA_SWAP_URL="https://github.com/mostlygeek/llama-swap/releases/download/v223/llama-swap_223_linux_amd64.tar.gz"


RUN apt-get update && apt-get install -y git libssl-dev cmake ninja-build ccache curl && rm -rf /var/lib/apt/lists/*


WORKDIR /workspace
RUN --mount=type=cache,target=/root/.cache/ccache \
	mkdir llama.cpp && \
    cd llama.cpp && \
    git init && \
    git remote add origin $LLAMA_CPP_REPO && \
    git fetch --depth 1 origin $LLAMA_CPP_COMMIT && \
    git checkout FETCH_HEAD && \
    HIPCXX="$(hipconfig -l)/clang" \
    HIP_PATH="$(hipconfig -R)" \
	cmake -S . -B build -G Ninja \
    -DGGML_HIP=ON \
    -DGPU_TARGETS=gfx1201 \
    -DGGML_HIP_ROCWMMA_FATTN=ON \
    -DGGML_HIP_GRAPHS=ON \
    -DGGML_LTO=ON \
    -DGGML_NATIVE=ON \
    -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build


RUN curl -sSL -o llama_swap.tar.gz $LLAMA_SWAP_URL && \
    ACTUAL_HASH=$(cksum -a sha256 --untagged llama_swap.tar.gz | awk '{print $1}') && \
    if [ "$LLAMA_SWAP_CHECKSUM" != "$ACTUAL_HASH" ]; then echo "Checksum mismatch!"; exit 1; fi && \
    tar -xzf llama_swap.tar.gz && \
    rm llama_swap.tar.gz


ENTRYPOINT ["/workspace/llama-swap"]
