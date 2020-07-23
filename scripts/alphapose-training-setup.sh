#!/bin/bash

cd /build/AlphaPose

curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/fast_421_res152_256x192.pth > pretrained_models/fast_421_res152_256x192.pth
curl https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/alphapose/wf_256x192_res152_lr1e-3_1x-duc.yaml > data/wf_256x192_res152_lr1e-3_1x-duc.yaml

pip3 install boto3
pip3 install protobuf
pip3 install numpy==1.17.5

python /scripts/s3_download.py --s3-file-url s3://wf-sagemaker-us-east-2/final_training_sets/wf-coco-gt-v0.1.tgz --dest /build/AlphaPose/data/
tar xvf ./data/wf-coco-gt-v0.1.tgz -C ./data
