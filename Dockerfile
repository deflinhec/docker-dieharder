FROM alpine:3.12.1 AS base
LABEL maintainer "deflinhec <deflinhec@gmail.com>"

RUN apk add \
  apk-tools-static busybox-static \
  make cmake automake autoconf \
  curl ca-certificates && \
  apk.static -U add libtool \
    chrpath rng-tools gsl\
    haveged build-base \
    gsl-dev rpm-dev

WORKDIR /project
RUN mkdir -pm 0700 ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo '%_topdir %(echo $HOME)/rpmbuild' >> ~/.rpmmacros && \
    curl -k http://webhome.phy.duke.edu/~rgb/General/dieharder/dieharder-3.31.1.tgz | \
    tar -xz -C /project && cd /project/dieharder-3.31.1 && \
    curl -k -O http://cvs.savannah.gnu.org/viewvc/*checkout*/config/config/config.guess && \
    curl -k -O http://cvs.savannah.gnu.org/viewvc/*checkout*/config/config/config.sub && \
    autoreconf --install && ./autogen.sh && ./configure --prefix=/usr/local && \
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
RUN apk add gsl gsl-dev
