#!/bin/bash

set -e

PARAMS=""
YOLO_VERSION=""
COCO_S3_URL=""
COCO_NAMES_URL="https://wildflower-tech-public.s3.us-east-2.amazonaws.com/models/darknet/coco.names"
GPUS=0
SUBDIVISIONS=64
IMG_SIZE=832
MAX_BATCHES=3500
while (( "$#" )); do
  case "$1" in
    --yolo)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        YOLO_VERSION=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --coco-s3-url)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        COCO_S3_URL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --coco-names-url)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        COCO_NAMES_URL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;       
    --gpus)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        GPUS=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --subdivisions)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        SUBDIVISIONS=$2
	shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --img-size)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        IMG_SIZE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --max-batches)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MAX_BATCHES=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

if ! command -v bc &> /dev/null; then
    apt install bc -y
fi

PARAM_ARRAY=($PARAMS)

if [ "v${YOLO_VERSION}" == 'vyolov3' ]; then
  yolo_input="./cfg/yolov3-spp.train.cfg ./build/darknet/x64/yolov3-spp-pretrained.conv.113"
  yolo_cfg_name="yolov3-spp.train.cfg"
elif [ "v${YOLO_VERSION}" == 'vyolov4' ]; then
  yolo_input="./cfg/yolov4.cfg ./build/darknet/x64/yolov4-pretrained.conv.161"
  yolo_cfg_name="yolov4.cfg"
else
  echo "Error: Arg1 should specify yolov3 | yolov4"
  exit 0
fi

if [ "v${COCO_S3_URL}" != 'v' ]; then
  cd /build/wf-coco-to-yolo/
  if [ ! -d "/build/wf-coco-to-yolo/venv" ]; then
    python -m venv env
  fi
  source env/bin/activate

  if ! pip show boto3 &> /dev/null; then
    pip install boto3
  fi

  filename_with_extension="${COCO_S3_URL##*/}"
  filename_naked="${filename_with_extension%.tar.gz}"

  if [ ! -f "/build/darknet/data/coco/${filename_with_extension}" ]; then
    echo "Downloading ${filename_with_extension}..."
    python /build/darknet/scripts/s3_download.py --s3-file-url ${COCO_S3_URL} --dest /build/darknet/data/coco
  fi

  if [ ! -d "/build/darknet/data/coco/${filename_naked}" ]; then
    tar -xvf "/build/darknet/data/coco/${filename_with_extension}" -C /build/darknet/data/coco/
  fi

  mkdir -p /build/wf-coco-to-yolo/data
  rm -rf /build/wf-coco-to-yolo/data/*
  cp -a /build/darknet/data/coco/${filename_naked}/. /build/wf-coco-to-yolo/data/

  /build/wf-coco-to-yolo/convert.sh --coco-names-url ${COCO_NAMES_URL}

  mkdir -p /build/darknet/data/wf/
  rm -rf /build/darknet/data/wf/*
  mv /build/wf-coco-to-yolo/output/wf/* /build/darknet/data/wf/

  deactivate
  cd /build/darknet
fi

yolo_cfg_path="./cfg/${yolo_cfg_name}"

# Compute step size from max_batch
step_80=$(printf "%.0f\n" $(echo "${MAX_BATCHES}*.8" | bc))
step_90=$(printf "%.0f\n" $(echo "${MAX_BATCHES}*.9" | bc))
steps="${step_80},${step_90}"

# Set the convolution layer filter size based on # of classes
classes=$(cat data/wf/wf_yolo.data | awk '/classes.*/ {split($0,x,"="); print x[2]}')
class_filters=$(echo "(${classes}+5)*3" | bc)

sed -i -E "s/subdivisions.*=.*[[:digit:]]+/subdivisions=${SUBDIVISIONS}/g" "${yolo_cfg_path}"
sed -i -E "s/width.*=.*[[:digit:]]+/width=${IMG_SIZE}/g" "${yolo_cfg_path}"
sed -i -E "s/height.*=.*[[:digit:]]+/height=${IMG_SIZE}/g" "${yolo_cfg_path}"
sed -i -E "s/max_batches.*=.*[[:digit:]]+/max_batches=${MAX_BATCHES}/g" "${yolo_cfg_path}"
sed -i -E "s/steps.*=.*[[:digit:]]+/steps=${steps}/g" "${yolo_cfg_path}"
sed -i -E "s/filters=255/filters=${class_filters}/g" "${yolo_cfg_path}"
sed -i -E "s/classes.*=.*[[:digit:]]+/classes=${classes}/g" "${yolo_cfg_path}"

cp "${yolo_cfg_path}" ./backup/${yolo_cfg_name}

exec /build/darknet/darknet detector train data/wf/wf_yolo.data ${yolo_input} -dont_show -map -gpus ${GPUS}

cp chart.png ./backup/chart.png

