FROM alpine:3.12.1 AS base
LABEL maintainer "deflinhec <deflinhec@gmail.com>"

RUN apk add \
  apk-tools-static \
  busybox-static && \
  apk.static -U add libtool\
    chrpath make cmake rng-tools \
    haveged build-base gsl \
    gsl-dev rpm-dev

WORKDIR /project
RUN wget -c \
    http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-3.31.1.tgz -O - | \
    tar -xz -C /project && cd /project/dieharder-3.31.1 && \
    mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo '%_topdir %(echo $HOME)/rpmbuild' >> ~/.rpmmacros && \
    ./autogen.sh && ./configure --prefix=/usr/local && \
    sed -i '16s/.*/chrpath gsl-dev/' \
    ./dieharder.spec && \
    sed -i '129s/.*/# /' \
    ./dieharder.spec && \
    sed -i '66i #define M_PI    PI' \
    ./include/dieharder/libdieharder.h && \
    sed -i '262i typedef unsigned int uint;' \
    ./include/dieharder/libdieharder.h && \
    make install

FROM alpine:latest AS dieharder

COPY --from=base /usr/local /usr/local
RUN apk add gsl && gsl-dev
