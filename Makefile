.PHONY: build-alphapose build-openpose

VERSION ?= 0


build-alphapose:
	echo "starting build"
	docker build -t wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v$(VERSION) -f alphapose-base.dockerfile .
	echo "building alphapose"
	docker run --gpus all -v $$(pwd)/scripts:/scripts wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v$(VERSION) bash /scripts/alphapose-builder.sh
	echo "committing"
	@docker container commit $$(docker container ls -all | grep alphapose-base-v${VERSION} | awk '{print $$1}')  wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v${VERSION}
	echo "commited"
	@docker push wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v${VERSION}

build-openpose:
	echo "starting build"
	docker build -t wildflowerschools/wf-deep-docker:cuda10.2-openpose-base-v$(VERSION) -f openpose-base.dockerfile .
	docker push wildflowerschools/wf-deep-docker:cuda10.2-openpose-base-v$(VERSION)
