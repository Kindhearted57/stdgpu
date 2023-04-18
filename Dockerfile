FROM debian
RUN apt-get update && apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential wget rsync gcc g++ clang make cmake vim wget python python-dev tar libomp-dev libthrust-dev && apt-get clean 

RUN mkdir -p /app/stdgpu
COPY . /app/stdgpu

RUN mkdir -p /app/stdgpu/build
WORKDIR /app/stdgpu/build
RUN cmake -DSTDGPU_BACKEND=STDGPU_BACKEND_OPENMP .. && make -j8
