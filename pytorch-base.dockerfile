FROM nvidia/cuda:10.1-base-ubuntu18.04

RUN apt update && \
    apt install -y python3 python3-pip

RUN pip3 install torch torchvision

