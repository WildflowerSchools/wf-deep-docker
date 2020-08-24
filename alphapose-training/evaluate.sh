#!/bin/bash

PARAMS=""
DETECTOR_TYPE="yolov3"
DATASET_TYPE="wfcoco17"
CONFIG=""
MODEL=""
COCO_DIR=""
while (( "$#" )); do
  case "$1" in
    --detector-type)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DETECTOR_TYPE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --dataset-type)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DATASET_TYPE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --config)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CONFIG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --model)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MODEL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --coco-dir)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        COCO_DIR=$2
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

if [ "v${CONFIG}" == "v" ]; then
    echo "--config required"
    exit 1
fi

if [ "v${MODEL}" == "v" ]; then
    echo "--model required"
    exit 1
fi

if [ "v${COCO_DIR}" == "v" ]; then
    echo "--coco-dir required"
    exit 1
fi

if ! pip show natsort &> /dev/null; then
  pip install natsort
fi

if pip show pycocotools &> /dev/null; then
  pip uninstall pycocotools
fi

image_dir="${COCO_DIR}/images"

python scripts/demo_inference.py \
  --cfg ${CONFIG} \
  --checkpoint ${MODEL} \
  --indir ${image_dir} \
  --outdir ./data/output \
  --detector ${DETECTOR_TYPE} \
  --sp

python3 scripts/evaluate.py \
  --coco-data-type ${DATASET_TYPE} \
  --coco-data-dir ${COCO_DIR}
