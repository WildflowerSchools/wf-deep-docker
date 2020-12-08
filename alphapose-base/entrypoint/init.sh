#!/bin/bash

source util.sh


PARAMS=""
declare -A KWARGS

DETECTOR="wfyolov3"
POSE_MODEL=""
TRACKER_MODEL=""
CMD="python3 scripts/demo_inference.py"


function load_assets {
  download_detector ${DETECTOR}
  detector_config=${G_DETECTOR_CONFIG}
  detector_weights=${G_DETECTOR_WEIGHTS}
  detector_type=${G_DETECTOR_TYPE}

  download_pose_model ${POSE_MODEL}
  pose_model_weights=${G_POSE_MODEL_WEIGHTS}
  pose_model_config=${G_POSE_MODEL_CONFIG}

  download_tracker_model ${TRACKER_MODEL}
  tracker_model=${G_TRACKER_MODEL}
}

function validate {
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

  if [ ! -f "${pose_model_weights}" ]; then
      echo "Pose model weights '${pose_model_weights}' does not exist"
      exit 1
  fi

  if [ ! -f "${pose_model_config}" ]; then
      echo "Pose model config '${pose_model_config}' does not exist"
      exit 1
  fi

  if [ ! -f "${tracker_model}" ]; then
      echo "Tracker model '${tracker_model}' does not exist"
      exit 1
  fi
}

function stage_inference_config {
  alphapose_cfg_dir="/build/AlphaPose/data/pose_cfgs"
  mkdir -p ${alphapose_cfg_dir}

  alphapose_cfg_path="${alphapose_cfg_dir}/wf_alphapose_inference_config.yaml"
  cp ${pose_model_config} ${alphapose_cfg_path}
}

function prepare_config {
  stage_inference_config

  # Hoping these attributes are never reused...
  sed -i -E "s/.*NAME:.*/  NAME: ${DETECTOR}/g" "${alphapose_cfg_path}"
  sed -i -E "s/.*CONFIG:.*/  CONFIG: $(regex_safe ${detector_config})/g" "${alphapose_cfg_path}"
  sed -i -E "s/.*WEIGHTS:.*/  WEIGHTS: $(regex_safe ${detector_weights})/g" "${alphapose_cfg_path}"
}


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
    --pose-model)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        POSE_MODEL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
       	exit 1
      fi
      ;;
    --tracker-model)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        TRACKER_MODEL=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
       	exit 1
      fi
      ;;
  esac
done


load_assets
validate
prepare_config
