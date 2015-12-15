LH_ROOT=../lh_root


docker-build:
	docker build -t ini-api .

docker-run-develop: docker-build
	-docker rm ini-api-dev
	docker run \
		--rm -ti \
		-p 3000:3000 --name ini-api-dev \
		-v $(PWD)/lib:/app/lib \
		-v $(LH_ROOT):/data \
		ini-api npm run nodemon

.PHONY: docker-build docker-run-develop
