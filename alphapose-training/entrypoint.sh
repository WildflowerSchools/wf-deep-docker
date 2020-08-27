#!/bin/bash

set -e

DETECTOR_YOLOV3_DARKNET_CONFIG_PATH="/build/AlphaPose/detector/yolo/cfg/yolov3-spp.cfg"
DETECTOR_YOLOV3_DARKNET_WEIGHTS_URL="s3://wildflower-tech-public/models/alphapose/yolov3-spp.weights"

DETECTOR_YOLOV4_DARKNET_CONFIG_PATH="/build/AlphaPose/detector/yolo_v4/cfg/yolov4.cfg"
DETECTOR_YOLOV4_DARKNET_WEIGHTS_URL="s3://wildflower-tech-public/models/alphapose/yolov4.weights"

DETECTOR_YOLOV3_WF_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/yolov3-spp.wf.0.2.cfg"
DETECTOR_YOLOV3_WF_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/yolov3-spp.wf.0.2.weights"

DETECTOR_YOLOV4_WF_CONFIG_URL=""
DETECTOR_YOLOV4_WF_WEIGHTS_URL=""

PRETRAINED_FAST_421_RES152_256x192="s3://wildflower-tech-public/models/alphapose/fast_421_res152_256x192.pth"

function regexSafe {
  echo "$(<<< "$1" sed -e 's`[][\\/.*^$]`\\&`g')"
}

PARAMS=""
DETECTOR="wfyolov3"
DATASET_TYPE="wfcoco17"
DATASET_URL=""
IMG_SIZE=256 # Specifically width, image aspect ratio converted to 4:3
BATCH_SIZE=32
PRETRAINED=""
LEARNING_RATE="0.001"
EPOCHS=200
NUM_CLASSES=80
while (( "$#" )); do
  case "$1" in
    --detector)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DETECTOR=$2
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
    --batch-size)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        BATCH_SIZE=$2
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
    --dataset)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        DATASET_URL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --pretrained)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        PRETRAINED=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
       	exit 1
      fi
      ;; 
    --learning-rate)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        LEARNING_RATE=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
       	exit 1
      fi
      ;; 
    --epochs)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        EPOCHS=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
       	exit 1
      fi
      ;;
    --num-classes)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        NUM_CLASSES=$2
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

if ! pip show boto3 &> /dev/null; then
    pip3 install boto3
fi

alphapose_cfg_path="/build/AlphaPose/data/cfgs/wf_alphapose_config.yaml"
cp /build/AlphaPose/configs/wf/train_template.yaml ${alphapose_cfg_path}

# Compute step size from max_batch
img_width=${IMG_SIZE}
img_height=$(printf "%.0f\n" $(echo "${img_width}*.75" | bc))
heatmap_width=$(printf "%.0f\n" $(echo "${img_width}*.25" | bc))
heatmap_height=$(printf "%.0f\n" $(echo "${img_height}*.25" | bc))

if [ "v${DATASET_TYPE}" == "vwfcoco17" ]; then
   alphapose_dataset_type="Wfcoco17" 
   alphapose_dataset_type_det="Wfcoco17_det"
else
   echo "Invalid dataset-type"
   exit 1
fi

dataset_dir="/build/AlphaPose/data/wf-coco"
mkdir -p ${dataset_dir}
if [ "v${DATASET_URL}" != "v" ]; then
    dataset_compressed_filename="${DATASET_URL##*/}"
    dataset_compressed_file="${dataset_dir}/${dataset_compressed_filename}"
    dataset="${dataset_compressed_file%.tar.gz}"
    if [ ! -d ${dataset} ]; then
        if [ ! -f ${dataset_compressed_file} ]; then
            echo "Downloading ${dataset_compressed_filename}..."
            python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${DATASET_URL} --dest ${dataset_dir}
        fi
        mkdir -p ${dataset} && tar -xzvf ${dataset_compressed_file} -C ${dataset}
    fi
else
    echo "Dataset URL invalid"
    exit 1
fi

test_detector_dir="/build/AlphaPose/exp/det_results"
mkdir -p ${test_detector_dir}
rm -rf ${test_detector_dir}/*.json

detector_type="yolov3"
detector_config_dir="/build/AlphaPose/data/cfgs"
detector_weights_dir="build/AlphaPose/data/weights"
if [ "v${DETECTOR}" == "vwfyolov3" ]; then
    detector_config_filename="${DETECTOR_YOLOV3_WF_CONFIG_URL##*/}"
    detector_config="${detector_config_dir}/${detector_config_filename}"
    if [ ! -f ${detector_config} ]; then
      echo "Downloading ${detector_config}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${DETECTOR_YOLOV3_WF_CONFIG_URL} --dest ${detector_config_dir}
    fi

    detector_weights_filename="${DETECTOR_YOLOV3_WF_WEIGHTS_URL##*/}"
    detector_weights="${detector_config_dir}/${detector_weights_filename}"
    if [ ! -f ${detector_weights} ]; then
      echo "Downloading ${detector_weights}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${DETECTOR_YOLOV3_WF_WEIGHTS_URL} --dest ${detector_config_dir}
    fi
else
    echo "Invalid detector"
    exit 1
fi

pretrained_dir="/build/AlphaPose/pretrained_models"
if [ "v${PRETRAINED}" == "vfast_421_res152_256x192.pth" ]; then
    pretrained="${pretrained_dir}/${PRETRAINED}"   
    if [ ! -f ${pretrained} ]; then
      echo "Downloading ${PRETRAINED_FAST_421_RES152_256x192}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${PRETRAINED_FAST_421_RES152_256x192} --dest ${pretrained_dir}
    fi
elif [ "v${PRETRAINED}" != "v" ]; then
    echo "Invalid pretrained"
    exit 1
fi

if [ ! -f ${detector_config} ]; then
    echo "Detector file '${detector_config}' does not exist"
    exit 1
fi

if [ ! -f ${detector_weights} ]; then
    echo "Weights file '${detector_weights}' does not exist"
    exit 1
fi

if [ ! -f ${alphapose_cfg_path} ]; then
    echo "Alphapose config file '${alphapose_cfg_path}' does not exist"
    exit 1
fi

if [ ! -d ${dataset} ]; then
    echo "Alphapose training directory '${dataset}' does not exist"
    exit 1
fi

if [ ! -d "${dataset}/images" ]; then
    echo "Alphapose training image directory '${dataset}/images' does not exist"
    exit 1
fi

if [ ! -f "${dataset}/wf-train.json" ]; then
    echo "Alphapose training json file '${dataset}/wf-train.json' does not exist"
    exit 1
fi

if [ ! -f "${dataset}/wf-val.json" ]; then
    echo "Alphapose validation json file '${dataset}/wf-val.json' does not exist"
    exit 1
fi

# Compute Step Rate
LR_STEP_1=$(printf "%.0f\n" $(echo "${EPOCHS}*.45" | bc))
LR_STEP_2=$(printf "%.0f\n" $(echo "${EPOCHS}*.6" | bc))
DPG_MILESTONE=$(printf "%.0f\n" $(echo "${EPOCHS}*.7" | bc))
DPG_STEP_1=$(printf "%.0f\n" $(echo "${EPOCHS}*.8" | bc))
DPG_STEP_2=$(printf "%.0f\n" $(echo "${EPOCHS}*.95" | bc))

sed -i -E "s/\{ROOT\}/$(regexSafe ${dataset})/g" "${alphapose_cfg_path}"
sed -i -E "s/\{TYPE\}/${alphapose_dataset_type}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{TYPE_DET\}/${alphapose_dataset_type_det}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{IMG_PREFIX\}/images/g" "${alphapose_cfg_path}"
sed -i -E "s/\{ANN_TRAIN\}/wf-train.json/g" "${alphapose_cfg_path}"
sed -i -E "s/\{ANN_VAL\}/wf-val.json/g" "${alphapose_cfg_path}"
sed -i -E "s/\{BATCH_SIZE\}/${BATCH_SIZE}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{IMG_WIDTH\}/${img_width}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{IMG_HEIGHT\}/${img_height}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{HEATMAP_WIDTH\}/${heatmap_width}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{HEATMAP_HEIGHT\}/${heatmap_height}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DETECTOR_NAME\}/${DETECTOR}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DETECTOR_CONFIG\}/$(regexSafe ${detector_config})/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DETECTOR_WEIGHTS\}/$(regexSafe ${detector_weights})/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DET_FILE_DIR\}/$(regexSafe "${test_detector_dir}")/g" "${alphapose_cfg_path}"
sed -i -E "s/\{PRETRAINED\}/$(regexSafe ${pretrained})/g" "${alphapose_cfg_path}"
sed -i -E "s/\{LEARNING_RATE\}/${LEARNING_RATE}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{EPOCHS\}/${EPOCHS}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{LR_STEP_1\}/${LR_STEP_1}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{LR_STEP_2\}/${LR_STEP_2}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DPG_MILESTONE\}/${DPG_MILESTONE}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DPG_STEP_1\}/${DPG_STEP_1}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{DPG_STEP_2\}/${DPG_STEP_2}/g" "${alphapose_cfg_path}"
sed -i -E "s/\{NUM_CLASSES\}/${NUM_CLASSES}/g" "${alphapose_cfg_path}"

python3 scripts/train.py --detector ${detector_type} --cfg ${alphapose_cfg_path} --exp-id wf_res152_${img_width}x${img_height}_$(date +%m-%d-%yT%T)
