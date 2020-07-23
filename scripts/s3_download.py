import argparse
import os
from urllib.parse import urlparse

import boto3


def parse():
    parser = argparse.ArgumentParser(description='S3 Authenticated Download')
    parser.add_argument('--s3-file-url',
                        type=str,
                        required=True,
                        help='Full S3 file URL (s3://<<BUCKET>>/<<?PATH>>/<<FILE_NAME>>)')
    parser.add_argument('--dest',
                        type=str,
                        default=os.getcwd(),
                        help='Destination folder, defaults to cwd')

    return parser.parse_args()


def download(s3_file_url, dest):
    s3 = boto3.client('s3')

    s3_parts = urlparse(s3_file_url, allow_fragments=False)

    s3.download_file(s3_parts.netloc, s3_parts.path.lstrip('/'), os.path.join(dest, os.path.basename(s3_file_url)))


if __name__ == "__main__":
    cfg = parse()
    download(cfg.s3_file_url, cfg.dest)

