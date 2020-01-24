FROM wildflowerschools/wf-deep-docker:pytorch-base-v2

RUN DEBIAN_FRONTEND=noninteractive apt update && \
        DEBIAN_FRONTEND=noninteractive apt install -y build-essential \
        libssl-dev \
        python3-dev \
        libyaml-dev \
        git && \
#    ln -s /usr/bin/python3 /usr/bin/python && \
#    ln -s /usr/bin/pip3 /usr/bin/pip && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir setuptools && \
    pip3 install --no-cache-dir build-utils

RUN DEBIAN_FRONTEND=noninteractive apt install -y python3-matplotlib cython

RUN pip3 install Cython

RUN mkdir /build

RUN cd /build && git clone https://github.com/MVIG-SJTU/AlphaPose.git

RUN cd /build/AlphaPose && python3 setup.py build develop --user

RUN cd /build/AlphaPose/PoseFlow && pip3 install -r requirements.txt 
