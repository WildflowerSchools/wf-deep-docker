FROM wildflowerschools/wf-deep-docker:cuda10.2-opencv-base-v0

RUN cd /build && git clone https://github.com/WildflowerSchools/darknet

WORKDIR /build/darknet

RUN sed -i 's/GPU=0/GPU=1/g' Makefile && \
    sed -i 's/CUDNN=0/CUDNN=1/g' Makefile && \
    sed -i 's/CUDNN_HALF=0/CUDNN_HALF=1/g' Makefile && \
    sed -i 's/OPENCV=0/OPENCV=1/g' Makefile && \
    make

RUN wget https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/yolov3-spp.weights && \
    wget https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/yolov4.weights && \
    ./darknet partial ./cfg/yolov3-spp.train.cfg yolov3-spp.weights ./build/darknet/x64/yolov3-spp-pretrained.conv.113 113 && \
    ./darknet partial ./cfg/yolov4.cfg yolov4.weights ./build/darknet/x64/yolov4-pretrained.conv.161 161 && \
    rm yolov3-spp.weights && rm yolov4.weights

RUN apt install -y vim
