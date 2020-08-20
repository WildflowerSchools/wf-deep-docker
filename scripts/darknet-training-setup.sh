#!/bin/bash

pip3 install boto3

cd /build/darknet

url=$1
filename_with_extension="${url##*/}"

if [ ! -f "${filename_with_extension}" ]; then
    echo "Downloading ${filename_with_extension} training data..."
    python3 /scripts/s3_download.py --s3-file-url ${url} --dest /build/darknet/wf_data/
    tar xvf ./wf_data/${filename_with_extension} -C ./wf_data
fi
