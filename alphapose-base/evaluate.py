import argparse
from functools import reduce
import json

import numpy as np
from pycocotools.coco import COCO
from pycocotools.cocoeval import COCOeval


def parse():
    parser = argparse.ArgumentParser(description='Evaluate COCO mAP Scores from Alphapose')
    parser.add_argument('--coco-data-type',
                        type=str,
                        required=True,
                        help='Valid options include coco | wfcoco17 | wfcoco18')
    parser.add_argument('--coco-data-dir',
                        type=str,
                        required=True,
                        help='COCO Data folder')
    parser.add_argument('--eval-type',
                        type=str,
                        required=True,
                        help='Valid options include keypoints | bbox' )

    return parser.parse_args()


def evaluate(coco_data_type, coco_data_dir, eval_type):
    homeDir='/build/AlphaPose'

    cocoFileName='wf-val.json'

    resFileName='alphapose-results.json'
    resDir='{}/data/output/'.format(homeDir)

    imageDir='{}/images'.format(coco_data_dir)

    annFile='{}/{}'.format(coco_data_dir, cocoFileName)
    resFile='{}/{}'.format(resDir, resFileName)

    cocoGt = COCO(annFile)

    if coco_data_type == 'wfcoco17':
        for _, ann in cocoGt.anns.items():
            if len(ann['keypoints']) == 18 * 3:
                ann['keypoints'] = ann['keypoints'][:17*3]
                ann['num_keypoints'] = reduce(lambda count, v: count + (v > 0), ann['keypoints'][2::3], 0)

    with open(resFile) as json_file:
        results = json.load(json_file)
        
    images = cocoGt.loadImgs(cocoGt.getImgIds())
    image_names = list(map(lambda img: img['file_name'], images))
    print("Total images in ann set %s: %d" % (annFile, len(images)))

    print("Number annotations in results: %d" % len(results))

    eval_image_ids = []    
    cocoValidResults = []
    for rs in results:
        if rs['image_id'] in image_names:
            idx = image_names.index(rs['image_id'])

            if images[idx]['id'] not in eval_image_ids:
                eval_image_ids.append(images[idx]['id'])
                
            rs['image_id'] = images[idx]['id']
            cocoValidResults.append(rs)

    print("Number annotations matched with ann file: %d" % len(cocoValidResults))
    cocoDt = cocoGt.loadRes(cocoValidResults)

    cocoEval = COCOeval(cocoGt, cocoDt, eval_type)
    cocoEval.params.catIds = [1]
    cocoEval.params.imgIds = eval_image_ids
    cocoEval.evaluate()
    cocoEval.accumulate()
    cocoEval.summarize()

    stats_names = ['AP', 'Ap .5', 'AP .75', 'AP (M)', 'AP (L)',
                   'AR', 'AR .5', 'AR .75', 'AR (M)', 'AR (L)']
    info_str = {}
    for ind, name in enumerate(stats_names):
        info_str[name] = cocoEval.stats[ind]

    print("")
    print("Average Precision against %d identified poses: %s" % (len(cocoValidResults), info_str['AP']))

if __name__ == "__main__":
    cfg = parse()
    evaluate(cfg.coco_data_type, cfg.coco_data_dir, cfg.eval_type)
