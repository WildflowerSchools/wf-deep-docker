.PHONY: build-alphapose build-openpose

VERSION ?= 0


build-alphapose:
	echo "starting build"
	docker build --no-cache -t wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v$(VERSION) -f alphapose-base.dockerfile .
	@docker push wildflowerschools/wf-deep-docker:cuda10.2-alphapose-base-v${VERSION}

build-openpose:
	echo "starting build"
	docker build -t wildflowerschools/wf-deep-docker:cuda10.2-openpose-base-v$(VERSION) -f openpose-base.dockerfile .
	docker push wildflowerschools/wf-deep-docker:cuda10.2-openpose-base-v$(VERSION)
