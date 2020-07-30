#!/bin/bash

cd /build/AlphaPose

if [ ! -f "./pretrained_models/fast_421_res152_256x192.pth" ]; then
	curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/fast_421_res152_256x192.pth > pretrained_models/fast_421_res152_256x192.pth
fi

mkdir -p ./detector/yolo_v4/data
if [ ! -f "./detector/yolo_v4/data/yolov4.weights" ]; then
	curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/yolov4.weights > detector/yolo_v4/data/yolov4.weights
fi

export PATH=/usr/local/cuda-10.2/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:LD_LIBRARY_PATH
pip3 install matplotlib==2.2.5
python3 setup.py build develop --user

if [ ! -f "./data/wf-coco-gt-v0.1.tgz" ]; then
    echo "Downloading training data..."
    python /scripts/s3_download.py --s3-file-url s3://wf-sagemaker-us-east-2/final_training_sets/wf-coco-gt-v0.1.tgz --dest /build/AlphaPose/data/
    tar xvf ./data/wf-coco-gt-v0.1.tgz -C ./data
fi
if [ ! -f "data/wf_256x192_res152_lr1e-3_1x-duc.yaml" ]; then
    echo "Downloading training config file..."
    curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/wf_256x192_res152_lr1e-3_1x-duc.yaml > data/wf_256x192_res152_lr1e-3_1x-duc.yaml
fi
