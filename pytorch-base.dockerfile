FROM nvidia/cuda:10.2-devel-ubuntu18.04

RUN apt update && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt update && \
    apt install -y git python3.8-dev build-essential

ENV PYTORCH_VERSION 1.7.0
ENV PYTORCH_BUILD_VERSION="${PYTORCH_VERSION}"
ENV PYTORCH_BUILD_NUMBER=1

RUN mkdir /build && \
    cd /build && git clone --recursive --depth 1 --branch v${PYTORCH_VERSION} https://github.com/pytorch/pytorch && \
    cd /build/pytorch && git submodule sync && git submodule update --init --recursive

RUN apt install -y curl && \
    curl "https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh" > /build/conda-install.sh && \
    bash /build/conda-install.sh -b -p /anaconda && \
    /anaconda/bin/conda install numpy ninja pyyaml mkl mkl-include setuptools cmake cffi typing -y

ENV PATH="/anaconda/bin:${PATH}"

# Switch to Anaconda Python
RUN ln -s /anaconda/bin/python /usr/bin/python && \
    rm /usr/bin/python3 && ln -s /anaconda/bin/python3 /usr/bin/python3 && \
    ln -s /usr/share/pyshared/lsb_release.py /anaconda/lib/python3.8/site-packages/lsb_release.py

RUN cd /build/pytorch && \
    PATH=/anaconda/bin:$PATH && \
    TORCH_NVCC_FLAGS="-D__CUDA_NO_HALF_OPERATORS__" && \
    CMAKE_PREFIX_PATH=/anaconda && \
    python setup.py install 
