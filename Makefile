deploy:
	git archive --format tar master | \
	ssh root@infoini.de 'cd /local/api && tar xv && \
		npm install && (pkill -u api run.sh || true) && echo starting && screen -S api -d -m sudo -u api /local/api/run.sh'

