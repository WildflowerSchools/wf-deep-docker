#!/bin/bash

source util.sh


REDIS="redis-cli -h localhost"
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

function inference {
  ARGS=""
  for KEY in "${!KWARGS[@]}"; do
    ARGS="$ARGS --$KEY ${KWARGS[$KEY]}"
  done
  environment_id=${KWARGS["environment_id"]:?"environment_id is required"}
  assignment_id=${KWARGS["assignment_id"]:?"assignment_id is required"}
  start_date=${KWARGS["start"]}  # 2020-03-10T00:00:00+0000
  duration=${KWARGS["dur"]:-"1d"}
  slot=${KWARGS["slot"]}
  state_id=$(producer hash $start_date $duration)
  date="${start_date: 0:4}/${start_date: 5:2}/${start_date: 8:2}"
  available_gpus=$($REDIS lrange "airflow.gpu.slots.available" 0 $($REDIS llen "airflow.gpu.slots.available"))

  echo $available_gpus

  if [[ ${KWARGS["verbose"]} == "true" ]]; then
      echo "available_gpus:: $available_gpus"
      echo "environment_id:: $environment_id"
      echo "assignment_id:: $assignment_id"
      echo "date:: $date"
      echo "state_id:: $state_id"
      echo "slot:: $slot"
  fi

  function log_verbose() {
      if [[ ${KWARGS["verbose"]} == "true" ]]; then
          echo $1
      fi
  }

  start=`date +%s`

  if [ -d /data/prepared/$environment_id/$assignment_id/$date/ ]
  then
      log_verbose /data/prepared/$environment_id/$assignment_id/$state_id.$slot.json
      for f in $(cat /data/prepared/$environment_id/$assignment_id/$state_id.$slot.json | jq -r '.[].video')
      do
          if [ ! -d /data/prepared/$environment_id/$assignment_id/$date/${f: -12:-4}/*.json ]; then
              echo "allocating GPU"
              selected_gpu=""
              outdir=/data/prepared/$environment_id/$assignment_id/$date/${f: -12:-4}/
              mkdir -p $outdir
              iterations=0
              while [[ "$selected_gpu" -eq "" ]]
              do
                  for gpu in $available_gpus
                  do
                      key="airflow.gpu.slots.$gpu"
                      aquired=$($REDIS setnx $key holding)
                      if [ $aquired -eq 1 ]; then
                          selected_gpu=$gpu
                          break 2
                      fi
                  done
                  if [[ ! "$selected_gpu" == "" ]]; then
                      break
                  fi
                  iterations=$(( iterations++ ))
                  if [ $iterations -gt 69 ]
                  then
                      exit 22
                  fi
                  sleep 1
              done
              if [[ ! "$selected_gpu" == "" ]]; then
                  set +e
                  echo "GPU aquired - executing inference $selected_gpu"
                  key="airflow.gpu.slots.$selected_gpu"
                  GPU=$selected_gpu ${CMD} --detector ${detector_type} --cfg ${alphapose_cfg_path} --checkpoint ${pose_model_weights} --sp --video ${f} --gpus ${selected_gpu} --outdir ${outdir}
                  $REDIS del $key
                  set -e
              fi
          fi
      done
  else
      echo "nothing to do"
  fi

  date

  end=`date +%s`
  runtime=$((end-start))

  if [[ ${KWARGS["verbose"]} == "true" ]]; then
      echo "runtime:: $runtime"
  fi
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
    --inference-command)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          CMD=$2
          shift 2
        else
          echo "Error: Argument for $1 is missing" >&2
         	exit 1
        fi
        ;;
    -*|--*=) # unsupported flags
      KEY=${1##*-}
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
         KWARGS["$KEY"]="$2"
         shift 2
      else
         KWARGS["$KEY"]="true"
            shift 1
     fi
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done


load_assets
validate
prepare_config
inference
