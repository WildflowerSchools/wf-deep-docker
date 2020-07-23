FROM wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v7

RUN cd build/AlphaPose && git fetch && git reset --hard origin/wf-training

