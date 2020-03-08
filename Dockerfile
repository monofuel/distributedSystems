FROM alpine
RUN apk update && apk add build-base lua5.3
RUN mkdir /code
ADD . /code/

