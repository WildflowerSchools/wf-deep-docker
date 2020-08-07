#!/bin/bash

set -e

PARAMS=""
GPUS=0
SUBDIVISIONS=64
IMG_SIZE=832
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

PARAM_ARRAY=($PARAMS)
YOLO_VERSION=${PARAM_ARRAY[0]}

if [ "${YOLO_VERSION}" = 'yolov3' ]; then
  yolo_input="./cfg/yolov3-spp.train.cfg ./build/darknet/x64/yolov3-spp-pretrained.conv.113"
  yolo_cfg_path="./cfg/yolov3-spp.train.cfg"
elif [ "${YOLO_VERSION}" = 'yolov4' ]; then
  yolo_input="./cfg/yolov4.cfg ./build/darknet/x64/yolov4-pretrained.conv.161"
  yolo_cfg_path="./cfg/yolov4.cfg"
else
  echo "Error: Arg1 should specify yolov3 | yolov4"
  exit 0
fi

sed -i -E "s/subdivisions=[[:digit:]]+/subdivisions=${SUBDIVISIONS}/g" "${yolo_cfg_path}"
sed -i -E "s/width=[[:digit:]]+/width=${IMG_SIZE}/g" "${yolo_cfg_path}"
sed -i -E "s/height=[[:digit:]]+/height=${IMG_SIZE}/g" "${yolo_cfg_path}"

exec /build/darknet/darknet detector train data/wf/wf_yolo.data ${yolo_input} -dont_show -map -gpus ${GPUS}
