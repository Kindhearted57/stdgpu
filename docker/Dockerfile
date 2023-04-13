FROM ubuntu:18.04
RUN apt-get update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential wget rsync

ADD ./deps/Makefile Makefile
RUN make cmake-3.24.1
RUN make cuda-12.1

VOLUME /project

ENV DOCKER=1
