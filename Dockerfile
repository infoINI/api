FROM node:4.2.1
EXPOSE 3000

RUN npm install -g nodemon

RUN mkdir /app
WORKDIR /app

ADD package.json ./
RUN npm install

RUN mkdir /data /uploads

ADD lib lib 
ADD static static
ADD bin bin 
ADD config.yaml config.yaml


CMD "npm start"
