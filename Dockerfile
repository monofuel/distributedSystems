FROM alpine
RUN apk update && apk add build-base lua5.3-dev lua5.3 luarocks
RUN luarocks-5.3 install luasocket
RUN mkdir /code
ADD . /code/

WORKDIR /code
