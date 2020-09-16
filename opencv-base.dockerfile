FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04

ENV OPENCV_VERSION=4.4.0

RUN apt update && \
    apt install -y build-essential && \
    apt install -y cmake git wget unzip libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev && \
    apt install -y python3 python3-dev python3-pip python3-numpy git && \
    apt install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev

RUN mkdir -p /build && cd /build && \
    wget -O opencv.zip https://github.com/Itseez/opencv/archive/${OPENCV_VERSION}.zip && unzip opencv.zip && \
    wget -O opencv_contrib.zip https://github.com/Itseez/opencv_contrib/archive/${OPENCV_VERSION}.zip && unzip opencv_contrib.zip && \
    rm opencv.zip opencv_contrib.zip

ENV PATH=/usr/local/cuda-10.2/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

RUN cd /build/opencv-${OPENCV_VERSION} && mkdir -p build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D OPENCV_GENERATE_PKGCONFIG=YES \
          -D WITH_CUDA=ON \
          -D WITH_CUDNN=ON \
          -D OPENCV_DNN_CUDA=ON \
          -D ENABLE_FAST_MATH=1 \
          -D CUDA_FAST_MATH=1 \
          -D WITH_CUBLAS=1 \
          -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules .. && \
          make -j7 && \
	  make install
