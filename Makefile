.PHONY: build

VERSION ?= 0


build:
	echo "starting build"
	docker build --no-cache -t wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v$(VERSION) -f alphapose-base.dockerfile .
	echo "building alphapose"
	docker run --gpus all -v $$(pwd)/scripts:/scripts wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v$(VERSION) bash /scripts/alphapose-builder.sh
	echo "committing"
	@docker container commit $$(docker container ls -all | grep alphapose-base-v${VERSION} | awk '{print $$1}')  wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v${VERSION}
	echo "commited"
	@docker push wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v${VERSION}

