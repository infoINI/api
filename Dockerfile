FROM node:4.2.1
EXPOSE 3000

RUN npm install -g nodemon

ENV DISABLE_AUTH false

# install textract dependencies
RUN apt-get update
RUN apt-get install -y poppler-utils catdoc tesseract-ocr unzip

RUN mkdir /app /data /uploads
WORKDIR /app

ADD package.json ./
RUN npm install

ADD lib lib
ADD static static
ADD bin bin



CMD [ "npm", "start" ]
