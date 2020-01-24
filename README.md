# Images for inference

An assemblage of images.


## pytorch-base

A base image that includes CUDA that have pytorch installed on it

## alphapose-base

A base image that extends `pytorch-base` adding the AlphaPose library. Building this image requires the GPU to be enabled. At this time we do a standard docker build and then run the image.

Once inside the image you execute the following to build and install AlphaPose:

```cd /build/AlphaPose && export PATH=/usr/local/cuda-10.2/bin:$PATH && \
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:LD_LIBRARY_PATH && \
    python3 setup.py build develop --user
```

