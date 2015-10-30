LH_ROOT=../lh_root

deploy:
	git archive --format tar master | \
	ssh root@infoini.de 'cd /local/api && tar xv && \
		npm install && (pkill -u api run.sh || true) && echo starting && screen -S api -d -m sudo -u api /local/api/run.sh'

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

.PHONY: docker-build deploy docker-run-develop
