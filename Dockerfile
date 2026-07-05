FROM docker.io/rocm/dev-ubuntu-24.04:7.2.4-complete


ARG LLAMA_CPP_REPO="https://github.com/ggml-org/llama.cpp.git"
ARG LLAMA_CPP_COMMIT="84de01a1f1c847292b8d90a9c0bff6619f2919be"

ARG LLAMA_SWAP_CHECKSUM="31f325b39b046869a4c6661803deeb522587ff4895a37f697d64a10e4a484742"
ARG LLAMA_SWAP_URL="https://github.com/mostlygeek/llama-swap/releases/download/v228/llama-swap_228_linux_amd64.tar.gz"


RUN apt-get update \
	&& apt-get install -y git libssl-dev cmake ninja-build ccache curl python3-pip libvulkan-dev glslc spirv-headers \
	&& rm -rf /var/lib/apt/lists/*
RUN pip3 install --break-system-packages huggingface_hub[cli]


WORKDIR /workspace
RUN --mount=type=cache,target=/root/.cache/ccache \
	git clone https://github.com/charlie12345/ROCmFPX.git \
	&& cd ROCmFPX \
	&& chmod +x scripts/*.sh \
	&& env JOBS=16 CFLAGS="-w" CXXFLAGS="-w" scripts/build-rdna4.sh

RUN curl -sSL -o llama_swap.tar.gz $LLAMA_SWAP_URL && \
    ACTUAL_HASH=$(cksum -a sha256 --untagged llama_swap.tar.gz | awk '{print $1}') && \
    if [ "$LLAMA_SWAP_CHECKSUM" != "$ACTUAL_HASH" ]; then echo "Checksum mismatch!"; exit 1; fi && \
    tar -xzf llama_swap.tar.gz && \
    rm llama_swap.tar.gz


ENTRYPOINT ["/workspace/llama-swap"]
