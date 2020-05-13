import os
from setuptools import setup, find_packages

BASEDIR = os.path.dirname(os.path.abspath(__file__))
VERSION = open(os.path.join(BASEDIR, 'VERSION')).read().strip()

BASE_DEPENDENCIES = [
    'opencv-python',
    'numpy',
]

# allow setup.py to be run from any path
os.chdir(os.path.normpath(BASEDIR))

setup(
    name='openpose',
    packages=find_packages(),
    version=VERSION,
    include_package_data=True,
    description='OpenPose: Real-time multi-person keypoint detection library for body, face, hands, and foot estimation',
    long_description="",
    url='https://github.com/CMU-Perceptual-Computing-Lab/openpose',
    author='CMU-Perceptual-Computing-Lab',
    author_email='',
    install_requires=BASE_DEPENDENCIES,
    keywords=['cv'],
    classifiers=[
        'Intended Audience :: Researchers',
        'License :: ACADEMIC OR NON-PROFIT ORGANIZATION NONCOMMERCIAL RESEARCH USE ONLY',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
    ]
)

