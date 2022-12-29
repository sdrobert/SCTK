FROM alpine:3.14

LABEL Description="NIST Speech Recognition Scoring Toolkit (SCTK)"

# SCTK dependencies
RUN apk add --update \
    alpine-sdk \
    git \
    perl \
    'cmake>3.15' \
 && rm -rf /var/cache/apk/*

WORKDIR /opt

# Build and install all SCTK tools
RUN git clone -b cmake https://github.com/sdrobert/SCTK \
 && cd SCTK \
 && cmake --version \
 && cmake -S . -B build -DFORCE_UTF_FILT=ON -DCMAKE_BUILD_TYPE=Release \
 && cd build \
 && make install

WORKDIR /var/sctk

CMD ["sclite"]
