FROM wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v7

WORKDIR /build/AlphaPose

RUN git fetch && git reset --hard origin/wf-training && \
    pip3 install torch==1.4.0 matplotlib==2.2.5 && python3 setup.py build develop --user

# Prep work for entrypoint.sh
RUN apt install bc -y && \
    pip3 install boto3 && \
    python3 -c "import torchvision.models as tm; tm.resnet152(pretrained=True)"

COPY scripts/s3_download.py alphapose-training/evaluate.sh alphapose-training/evaluate.py scripts/
COPY alphapose-training/entrypoint.sh /usr/local/bin/
ENV PATH=/usr/local/bin:${PATH}

ENTRYPOINT ["entrypoint.sh"]
