#!/bin/bash

source util.sh

function load_assets {
  download_detector ${DETECTOR}
  detector_config=${G_DETECTOR_CONFIG}
  detector_weights=${G_DETECTOR_WEIGHTS}
  detector_type=${G_DETECTOR_TYPE}

  download_pose_model ${POSE_MODEL}
  pose_model=${G_POSE_MODEL}

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

  if [ ! -f "${pose_model}" ]; then
      echo "Pose model '${pose_model}' does not exist"
      exit 1
  fi

  if [ ! -f "${tracker_model}" ]; then
      echo "Tracker model '${tracker_model}' does not exist"
      exit 1
  fi
}

function inference {
  clear_det_results

  python3 scripts/demo_inference.py --detector ${detector_type} --cfg ${alphapose_cfg_path} --checkpoint ${pose_model}
}

PARAMS=""
DETECTOR="wfyolov3"
POSE_MODEL=""
TRACKER_MODEL=""
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

load_assets
validate
inference

