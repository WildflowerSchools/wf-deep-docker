FROM nvidia/cuda:10.2-devel-ubuntu18.04

RUN apt update && \
    apt install -y python3 python3-pip git 

RUN mkdir /build

RUN cd /build && git clone --recursive https://github.com/pytorch/pytorch

RUN cd /build/pytorch && git submodule sync && git submodule update --init --recursive

RUN apt install -y curl

RUN curl "https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh" > /build/conda-install.sh

RUN bash /build/conda-install.sh -b -p /anaconda

RUN /anaconda/bin/conda install numpy ninja pyyaml mkl mkl-include setuptools cmake cffi typing

RUN pip3 install pyyaml numpy

RUN apt install -y build-essential cmake

RUN cd /build/pytorch && export CMAKE_PREFIX_PATH=/anaconda && python3 setup.py install

