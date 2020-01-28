FROM wildflowerschools/wf-deep-docker:cuda10.2-pytorch-base-v2

RUN apt update && \
        apt install -y build-essential \
        libssl-dev \
        python3-dev \
        libyaml-dev \
        git && \
    pip3 install --upgrade pip setuptools build-utils

RUN DEBIAN_FRONTEND=noninteractive apt install -y python3-matplotlib python-libsmdev libsm-dev

RUN pip3 install Cython

RUN cd /build && git clone https://github.com/MVIG-SJTU/AlphaPose.git

RUN curl https://bootstrap.pypa.io/get-pip.py | python3

RUN pip3 install --upgrade keyrings.alt 

