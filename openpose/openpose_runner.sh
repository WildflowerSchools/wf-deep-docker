#!/bin/bash

FLAG_KWARGS="|verbose|"

if [ ! -n "$FLAG_KWARGS" ]; then
    FLAG_KWARGS=""
fi

declare -a ARGS
declare -A KWARGS

while (( "$#" )); do
  case "$1" in
    -*|--*)
      KEY=${1##*-}
      if [[ "$FLAG_KWARGS" =~ "|${KEY}|" ]]; then
          KWARGS["$KEY"]="true"
          shift 1
      else
          if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            KWARGS["$KEY"]="$2"
            shift 2
          else
            KWARGS["$KEY"]="true"
            shift 1
          fi
      fi
      ;;
    *) # preserve positional arguments
      ARGS+=("$1")
      shift
      ;;
  esac
done


environment_id=${KWARGS["environment_id"]:-"724fe65b-f925-48a1-9ae0-ee1b85443d64"}  # 724fe65b-f925-48a1-9ae0-ee1b85443d64
assignment_id=${KWARGS["assignment_id"]:?"assignment_id is required"}
num_gpu=${KWARGS["num_gpu"]:-"1"}
num_gpu_start=${KWARGS["num_gpu_start"]:-"0"}
date=${KWARGS["date"]:-"2020/03/11"}

if [ ${KWARGS["verbose"]} = "true" ]; then
    echo "environment_id:: $environment_id"
    echo "assignment_id:: $assignment_id"
    echo "num_gpu:: $num_gpu"
    echo "num_gpu_start:: $num_gpu_start"
fi

start=`date +%s`

if [ -d /data/prepared/$environment_id/$assignment_id/$date/ ]
then
    for f in /data/prepared/$environment_id/$assignment_id/$date/*.mp4
    do
        matches=$(ls /data/prepared/$environment_id/$assignment_id/$date/${f: -12:-4}_*.json | wc -l)
        echo "$f $matches"
        if [[ $matches -lt 79 ]]; then
            echo "PROCESSING"
            ./build/examples/openpose/openpose.bin --video \
                $f \
                --model_folder /openpose/models/ --num_gpu "$num_gpu" \
                --num_gpu_start "$num_gpu_start" --model_pose BODY_25 \
                --write_json /data/prepared/$environment_id/$assignment_id/$date/ --display 0 --render_pose 0
        fi
    done
else
    echo "nothing to do"
fi

date

end=`date +%s`
runtime=$((end-start))

if [ ${KWARGS["verbose"]} = "true" ]; then
    echo "runtime:: $runtime"
fi

exit 0
