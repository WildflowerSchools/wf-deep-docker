#!/bin/bash

set -e

function init {
  if ! command -v bc &> /dev/null; then
      apt install bc -y
  fi

  if ! pip show boto3 &> /dev/null; then
      pip3 install boto3
  fi

  if pip show pycocotools &> /dev/null; then
    pip uninstall pycocotools -y
  fi
}

while (( "$#" )); do
  case "$1" in
    -*|--*=) # Hold onto flags
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        FLAGS="$FLAGS $1 $2"
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    *) # preserve positional arguments, single param for now
      PARAMS="$1"
      shift
      ;;
  esac
done

init

case "${PARAMS}" in
  train)
    source train.sh ${FLAGS}
    ;;
  inference)
    source inference.sh ${FLAGS}
    ;;
  *)
    echo "Usage: entrypoint.sh train | inference {FLAGS}"
    exit 1
esac

exit 0
