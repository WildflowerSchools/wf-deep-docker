#!/bin/bash

pip3 install boto3

cd /build/darknet

if [ ! -f "./wf_data/wf-yolo-v0.1.tgz" ]; then
    echo "Downloading training data..."
    python3 /scripts/s3_download.py --s3-file-url s3://wf-sagemaker-us-east-2/final_training_sets/wf-yolo-v0.1.tar.gz --dest /build/darknet/wf_data/
    tar xvf ./wf_data/wf-yolo-v0.1.tar.gz -C ./wf_data
fi
