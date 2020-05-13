FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

#get deps
RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  python3-dev python3-pip git g++ wget make libprotobuf-dev protobuf-compiler libopencv-dev \
  libgoogle-glog-dev libboost-all-dev libcaffe-cuda-dev libhdf5-dev libatlas-base-dev

#for python api
RUN pip3 install numpy opencv-python setuptools

#replace cmake as old version has CUDA variable bugs
RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz && \
tar xzf cmake-3.16.0-Linux-x86_64.tar.gz -C /opt && \
rm cmake-3.16.0-Linux-x86_64.tar.gz
ENV PATH="/opt/cmake-3.16.0-Linux-x86_64/bin:${PATH}"

#get openpose
WORKDIR /openpose
RUN git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose.git .

#build it
WORKDIR /openpose/build
RUN cmake -DBUILD_PYTHON=ON .. && make -j `nproc`
WORKDIR /openpose

# install python
RUN grep CMAKE_PROJECT_VERSION:STATIC /openpose/build/CMakeCache.txt | awk 'BEGIN { FS = "=" } ; { print $2; exit }' > /openpose/build/python/VERSION
COPY ./openpose/setup.py /openpose/build/python/setup.py
COPY ./openpose/MANIFEST.in /openpose/build/python/MANIFEST.in
RUN pip3 install /openpose/build/python/

COPY ./openpose/arg-parser /usr/bin/arg-parser
COPY ./openpose/openpose_runner.sh /usr/bin/openpose_runner

RUN chmod +x /usr/bin/arg-parser
RUN chmod +x /usr/bin/openpose_runner

