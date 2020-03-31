#!/bin/bash

cd /build/AlphaPose
export PATH=/usr/local/cuda-10.2/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:LD_LIBRARY_PATH
python3 setup.py build develop --user

mkdir -p detector/yolo/data
mkdir -p detector/tracker/data
mkdir -p pretrained_models/

curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/yolov3-spp.weights > detector/yolo/data/yolov3-spp.weights
curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/jde.1088x608.uncertainty.pt > jde.1088x608.uncertainty.pt
curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/fast_res50_256x192.pth > pretrained_models/fast_res50_256x192.pth
curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/256x192_res50_lr1e-3_1x.yaml > pretrained_models/256x192_res50_lr1e-3_1x.yaml

pip3 install opencv_contrib_python Image
rm /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

