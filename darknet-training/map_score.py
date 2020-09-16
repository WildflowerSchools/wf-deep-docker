from pycocotools.coco import COCO
from pycocotools.cocoeval import COCOeval
import numpy as np
import skimage.io as io
import argparse
import os
from urllib.parse import urlparse

def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("The file %s does not exist!" % arg)
    else:
        return arg


def parse():
    parser = argparse.ArgumentParser(description='Compute COCO mAP using YOLO detect output')
    parser.add_argument('--res-file', required=True, type=lambda x: is_valid_file(parser, x))
    parser.add_argument('--coco-ann-file', required=True, type=lambda x: is_valid_file(parser, x))

    return parser.parse_args()


def compute(coco_ann_file, res_file):
    annType = ['bbox']
    annType = annType[0]      #specify type here
    prefix = 'person_keypoints' if annType=='keypoints' else 'instances'
    print("Running demo for *%s* results." % (annType))

    #initialize COCO ground truth api
    cocoGt=COCO(coco_ann_file)

    #initialize COCO detections api
    cocoDt=cocoGt.loadRes(res_file)

    import json
    dts = json.load(open(res_file,'r'))
    imgIds = [imid["image_id"] for imid in dts]
    imgIds = sorted(list(set(imgIds)))
    del dts
    # print(imgIds)

    # running evaluation
    cocoEval = COCOeval(cocoGt,cocoDt,annType)
    cocoEval.params.imgIds  = imgIds
    cocoEval.evaluate()
    cocoEval.accumulate()
    cocoEval.summarize()

if __name__ == "__main__":
    cfg = parse()
    compute(cfg.coco_ann_file, cfg.res_file)
