FROM docker.io/rocm/dev-ubuntu-24.04:7.2.4-complete


ARG LLAMA_CPP_REPO="https://github.com/ggml-org/llama.cpp.git"
ARG LLAMA_CPP_COMMIT="84de01a1f1c847292b8d90a9c0bff6619f2919be"

ARG LLAMA_SWAP_CHECKSUM="31f325b39b046869a4c6661803deeb522587ff4895a37f697d64a10e4a484742"
ARG LLAMA_SWAP_URL="https://github.com/mostlygeek/llama-swap/releases/download/v228/llama-swap_228_linux_amd64.tar.gz"


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
