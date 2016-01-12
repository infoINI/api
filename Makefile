LH_ROOT=../lh_root


docker-build:
	docker build -t ini-api .

docker-run-develop:
	echo "Starting with LH_ROOT=$(LH_ROOT)"
	-docker kill ini-api-elasticsearch
	-docker rm ini-api-elasticsearch
	docker run --name ini-api-elasticsearch \
		-v /tmp/esdata:/usr/share/elasticsearch/data \
		-d elasticsearch:2.1
	docker run \
		--rm -ti \
		--link ini-api-elasticsearch:elasticsearch \
		-p 3000:3000 --name ini-api-dev \
		-v $(PWD)/lib:/app/lib \
		-v $(LH_ROOT):/data \
		-e DISABLE_AUTH=true \
		ini-api npm run nodemon

.PHONY: docker-build docker-run-develop
