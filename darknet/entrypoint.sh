#!/bin/bash

set -e

PARAMS=""
GPUS=0
SUBDIVISIONS=64
IMG_SIZE=832
MAX_BATCHES=3500
while (( "$#" )); do
  case "$1" in
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
YOLO_VERSION=${PARAM_ARRAY[0]}

if [ "${YOLO_VERSION}" == 'yolov3' ]; then
  yolo_input="./cfg/yolov3-spp.train.cfg ./build/darknet/x64/yolov3-spp-pretrained.conv.113"
  yolo_cfg_name="yolov3-spp.train.cfg"
elif [ "${YOLO_VERSION}" == 'yolov4' ]; then
  yolo_input="./cfg/yolov4.cfg ./build/darknet/x64/yolov4-pretrained.conv.161"
  yolo_cfg_name="yolov4.cfg"
else
  echo "Error: Arg1 should specify yolov3 | yolov4"
  exit 0
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

