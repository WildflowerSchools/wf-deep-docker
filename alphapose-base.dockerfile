FROM wildflowerschools/wf-deep-docker:cuda10.2-pytorch-base-v3

ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y libsm-dev libgl1-mesa-glx 

RUN cd /build && git clone https://github.com/WildflowerSchools/AlphaPose.git

WORKDIR /build/AlphaPose

RUN python3 setup.py build develop --user && \
    pip uninstall pycocotools -y

# Prep work for entrypoint.sh
RUN apt install bc -y && \
    pip3 install boto3 && \
    python3 -c "import torchvision.models as tm; tm.resnet152(pretrained=True)"

COPY scripts/s3_download.py alphapose-base/evaluate.sh alphapose-base/evaluate.py scripts/
COPY alphapose-base/entrypoint/*.sh /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

ENTRYPOINT ["entrypoint.sh"]
