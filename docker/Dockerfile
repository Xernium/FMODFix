# Theos build environment for 32-bit (armv7) iOS tweaks.
# Build:  docker build -t fmodfix-theos docker
# Use:    docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/work -w /work fmodfix-theos make package FINALPACKAGE=1
# Authored by Claude Fable 5 on request of the user
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates make perl fakeroot xz-utils zstd unzip rsync \
      libncurses6 libtinfo6 libxml2 zlib1g libedit2 python3 file libplist-utils \
    && rm -rf /var/lib/apt/lists/*
ENV THEOS=/opt/theos
RUN git clone --recursive --depth 1 https://github.com/theos/theos.git $THEOS
ARG TOOLCHAIN_URL=https://github.com/L1ghtmann/llvm-project/releases/download/test-210562a/iOSToolchain-x86_64.tar.xz
RUN mkdir -p $THEOS/toolchain && curl -fsSL "$TOOLCHAIN_URL" | tar -xJ -C $THEOS/toolchain \
    && rm -f $THEOS/toolchain/linux/iphone/bin/plistutil   # linked against libplist-2.0.so.4 (not in bookworm); use Debian's /usr/bin/plistutil
# Only the old SDK that still ships armv7 stubs.
RUN curl -fsSL https://github.com/theos/sdks/archive/refs/heads/master.tar.gz \
      | tar -xz -C /tmp --wildcards 'sdks-master/iPhoneOS10.3.sdk/*' \
    && mv /tmp/sdks-master/iPhoneOS10.3.sdk $THEOS/sdks/ && rm -rf /tmp/sdks-master
ENV PATH=$THEOS/bin:$THEOS/toolchain/linux/iphone/bin:$PATH
