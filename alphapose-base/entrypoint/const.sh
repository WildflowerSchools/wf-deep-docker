#!/bin/bash

DETECTOR_YOLOV3_DARKNET_CONFIG_PATH="/build/AlphaPose/detector/yolo/cfg/yolov3-spp.cfg"
DETECTOR_YOLOV3_DARKNET_WEIGHTS_URL="s3://wildflower-tech-public/models/alphapose/yolov3-spp.weights"

DETECTOR_YOLOV4_DARKNET_CONFIG_PATH="/build/AlphaPose/detector/yolo_v4/cfg/yolov4.cfg"
DETECTOR_YOLOV4_DARKNET_WEIGHTS_URL="s3://wildflower-tech-public/models/alphapose/yolov4.weights"

DETECTOR_YOLOV3_WF_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/yolov3-spp.wf.0.2.cfg"
DETECTOR_YOLOV3_WF_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/yolov3-spp.wf.0.2.weights"

DETECTOR_YOLOV4_WF_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/yolov4.wf.0.2.cfg"
DETECTOR_YOLOV4_WF_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/yolov4.wf.0.2.weights"

PRETRAINED_FAST_421_RES152_256x192_CONFIG_PATH="/build/Alphapose/configs/coco/resnet/256x192_res152_lr1e-3_1x-duc.yaml"
PRETRAINED_FAST_421_RES152_256x192_WEIGHTS_URL="s3://wildflower-tech-public/models/alphapose/fast_421_res152_256x192.pth"

POSE_MODEL_RES152_256x192_WF_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192-0.1-08232020.yaml"
POSE_MODEL_RES152_256x192_WF_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192-0.1-08232020.pth"

POSE_MODEL_RES152_256x192_WF_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192-0.1-08232020.yaml"
POSE_MODEL_RES152_256x192_WF_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192-0.1-08232020.pth"

POSE_MODEL_RES152_256x192_WF_YOLOV4_CONFIG_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192.0.2.yolov4.yaml"
POSE_MODEL_RES152_256x192_WF_YOLOV4_WEIGHTS_URL="s3://wf-sagemaker-us-east-2/weights/alphapose-wf_res152_256x192.0.2.yolov4.pth"


TRACKER_JDE_1088x608_URL="s3://wildflower-tech-public/models/alphapose/jde.1088x608.uncertainty.pt"
