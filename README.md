# Images for inference

An assemblage of images.


## pytorch-base

A base image that includes CUDA that have pytorch installed on it

## alphapose-base

A base image that extends `pytorch-base` adding the AlphaPose library. At this time we do a standard docker build and then run the image.

The Alphapose image uses an entrypoint script that can run inference or training:

`entrypoint.sh train {FLAGS}`
`entrypoint.sh inference {FLAGS}`

These are custom scripts that execute the underlying Alphapose train.py and inference.py executables. Our scripts prepare the environment by downloading required files and modifying runtime configs.
