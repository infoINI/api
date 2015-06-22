#!/bin/bash

cd /local/api


sleep 5
for i in `seq 10`; do
	node app.js
done

