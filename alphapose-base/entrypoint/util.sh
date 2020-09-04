#!/bin/bash

source const.sh

function regex_safe {
  echo "$(<<< "$1" sed -e 's`[][\\/.*^$]`\\&`g')"
}

# Downloads detector config and weight files if necessary.
# Sets global variables with paths to config and weight files.
#
# Params:
#   $1: detector_type (string) - yolov3 | yolov4 | wfyolov3 | wfyolov4 
# Sets:
#   G_DETECTOR_CONFIG (string) - absolute path to the detector config file
#   G_DETECTOR_WEIGHTS (string) - absolute path to the detector weights file
#   G_DETECTOR_TYPE (string) - detector type - yolov3 | yolov4
function download_detector {
  local detector_type=$1

  G_DETECTOR_CONFIG=""
  G_DETECTOR_WEIGHTS=""
  G_DETECTOR_TYPE=""
  
  local detector_config_dir="/build/AlphaPose/data/detector_cfgs"
  local detector_weights_dir="/build/AlphaPose/data/detector_weights"
  mkdir -p ${detector_config_dir}
  mkdir -p ${detector_weights_dir}

  local detector_config_url=""
  local detector_weights_url=""
  local detector_config_filename=""
  local detector_weights_filename=""

  if [ "v${detector_type}" == "vyolov3" ]; then
      detector_weights_url="${DETECTOR_YOLOV3_DARKNET_WEIGHTS_URL}"
      
      detector_config_filename="${DETECTOR_YOLOV3_DARKNET_CONFIG_PATH}"
      detector_weights_filename="${DETECTOR_YOLOV3_DARKNET_WEIGHTS_URL##*/}"
      
      detector_type="yolov3"
  elif [ "v${detector_type}" == "vwfyolov3" ]; then
      detector_config_url="${DETECTOR_YOLOV3_WF_CONFIG_URL}"
      detector_weights_url="${DETECTOR_YOLOV3_WF_WEIGHTS_URL}"
      
      detector_config_filename="${DETECTOR_YOLOV3_WF_CONFIG_URL##*/}"
      detector_weights_filename="${DETECTOR_YOLOV3_WF_WEIGHTS_URL##*/}"
      
      detector_type="yolov3"
  elif [ "v${detector_type}" == "vyolov4" ]; then
      detector_weights_url="${DETECTOR_YOLOV4_DARKNET_WEIGHTS_URL}"
      
      detector_config_filename="${DETECTOR_YOLOV4_DARKNET_CONFIG_PATH}"
      detector_weights_filename="${DETECTOR_YOLOV4_DARKNET_WEIGHTS_URL##*/}"
      
      detector_type="yolov4"
  elif [ "v${detector_type}" == "vwfyolov4" ]; then
      detector_config_url="${DETECTOR_YOLOV4_WF_CONFIG_URL}"
      detector_weights_url="${DETECTOR_YOLOV4_WF_WEIGHTS_URL}"
    
      detector_config_filename="${DETECTOR_YOLOV4_WF_CONFIG_URL##*/}"
      detector_weights_filename="${DETECTOR_YOLOV4_WF_WEIGHTS_URL##*/}"
      detector_type="yolov4"
  else
      echo "Invalid detector"
      exit 1
  fi

  local detector_config="${detector_config_dir}/${detector_config_filename}"
  if [ "v${detector_config_url}" != "v" ] && [ ! -f ${detector_config} ]; then
      echo "Downloading ${detector_config}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${detector_config_url} --dest ${detector_config_dir}
  fi
  local detector_weights="${detector_weights_dir}/${detector_weights_filename}"
  if [ "v${detector_weights_url}" != "v" ]  && [ ! -f ${detector_weights} ]; then
      echo "Downloading ${detector_weights}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${detector_weights_url} --dest ${detector_weights_dir}
  fi

  G_DETECTOR_CONFIG=${detector_config}
  G_DETECTOR_WEIGHTS=${detector_weights}
  G_DETECTOR_TYPE=${detector_type}
}


# Download pose model if necessary.
# Sets global variable with path to model file.
#
# Params:
#   $1: pose_model (string) - fast_421_res152_256x192 | wf_res152_256x192 | wf_res152_256x192_yolov4
# Sets:
#   G_POSE_MODEL_WEIGHTS (string) - absolute path to the pose model file
#   G_POSE_MODEL_CONFIG (string) - absolute path to the pose config file
function download_pose_model {
  local pose_model=$1

  G_POSE_MODEL_WEIGHTS="" 
  G_POSE_MODEL_CONFIG=""

  local pretrained_dir="/build/AlphaPose/pretrained_models"
  mkdir -p ${pretrained_dir}

  local model_path=""
  local pose_model_weights_url=""
  local pose_model_config_url=""
  if [ "v${pose_model}" == "vfast_421_res152_256x192" ]; then
    pose_model_weights_url="${PRETRAINED_FAST_421_RES152_256x192_WEIGHTS_URL}"
    pose_model_config_path="${PRETRAINED_FAST_421_RES152_256x192_CONFIG_PATH}"
  elif [ "v${pose_model}" == "vwf_res152_256x192" ]; then
    pose_model_weights_url="${POSE_MODEL_RES152_256x192_WF_WEIGHTS_URL}"
    pose_model_config_url="${POSE_MODEL_RES152_256x192_WF_CONFIG_URL}"
  elif [ "v${pose_model}" == "vwf_res152_256x192_yolov4" ]; then
    pose_model_weights_url="${POSE_MODEL_RES152_256x192_WF_YOLOV4_WEIGHTS_URL}"
    pose_model_config_url="${POSE_MODEL_RES152_256x192_WF_YOLOV4_CONFIG_URL}"
  elif [ "v${pose_model}" != "v" ]; then
    echo "Invalid pose model ${pose_model}"
    exit 1
  fi

  local pose_model_weights_filename="${pose_model_weights_url##*/}"
  local model_weights_path="${pretrained_dir}/${pose_model_weights_filename}"
  if [ "v${model_weights_path}" != "v" ] && [ ! -f ${model_weights_path} ]; then
    echo "Downloading ${pose_model_weights_url}..."
    python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${pose_model_weights_url} --dest ${pretrained_dir}
  fi

  local pose_model_config_filename=""
  local model_config_path=""
  if [ "v${pose_model_config_path}" != "v" ]; then
    pose_model_config_filename="${pose_model_config_path##*/}"
    model_config_path="#{pose_model_config_path}"
  else 
    pose_model_config_filename="${pose_model_config_url##*/}"
    model_config_path="${pretrained_dir}/${pose_model_config_filename}"
    if [ "v${model_config_path}" != "v" ] && [ ! -f ${model_config_path} ]; then
      echo "Downloading ${pose_model_config_url}..."
      python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${pose_model_config_url} --dest ${pretrained_dir}
    fi
  fi

  G_POSE_MODEL_WEIGHTS="${model_weights_path}"
  G_POSE_MODEL_CONFIG="${model_config_path}"
}


# Download tracker model if necessary.
# Sets global variable with path to model file.
#
# Params:
#   $1: tracker_model (string) - jde_1088x608
# Sets:
#   G_TRACKER_MODEL (string) - absolute path to the pose model file
function download_tracker_model {
  local tracker_model=$1

  G_TRACKER_MODEL=""
  
  local tracker_dir="/build/AlphaPose/data/tracker_weights"
  mkdir -p ${tracker_dir}

  local tracker_model_url=""
  if [ "v${tracker_model}" == "jde_1088x608" ]; then
    tracker_model_url="${TRACKER_JDE_1088x608_URL}"
  elif [ "v${tracker_model}" != "v" ]; then
    echo "Invalid tracker model ${tracker_model}"
    exit 1
  fi

  local tracker_model_filename="${tracker_model_url##*/}"
  local model_path="${tracker_dir}/${tracker_model_filename}"
  if [ ! -f ${model_path} ]; then
    echo "Downloading ${tracker_model_url}..."
    python3 /build/AlphaPose/scripts/s3_download.py --s3-file-url ${tracker_model_url} --dest ${tracker_dir}
  fi

  G_TRACKER_MODEL="${model_path}"
}


# Download training dataset if necessary.
# Sets global variable with path to training data directory.
#
# Params:
#   $1: dataset_url (string) - s3 URL to the training set data
# Sets:
#   G_DATASET_DIR (string) - absolute path to the training data directory
function download_training_data {
  local dataset_url=$1

  G_DATASET_DIR=""
  
  local dataset_dir="/build/AlphaPose/data/wf-coco"
  mkdir -p ${dataset_dir}

  if [ "v${DATASET_URL}" != "v" ]; then
      local dataset_compressed_filename="${DATASET_URL##*/}"
      local dataset_compressed_file="${dataset_dir}/${dataset_compressed_filename}"
      local dataset="${dataset_compressed_file%.tar.gz}"
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

  G_DATASET_DIR="${dataset}"
}
