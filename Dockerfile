ARG BOARD=rg280m
FROM debian:buster AS tool-chain-repo
RUN apt-get update && apt-get install -y \
    bc \
    bison \
    build-essential \
    bzr \
    cpio \
    default-jdk \
    dosfstools \
    expat \
    expat \
    file \
    flex \
    g++ \
    g++-multilib \
    gcc-multilib \
    gettext \
    git \
    intltool-debian \
    java-wrappers \
    libc6-dev-i386 \
    libncurses-dev \
    libncurses5 \
    libncurses5-dev \
    libssl-dev \
    libtinfo5 \
    libxml-libxml-perl \
    libxml-parser-perl \
    libxml2 \
    mercurial \
    mtools \
    python \
    rsync \
    subversion \
    sudo \
    squashfs-tools \
    texinfo \
    u-boot-tools \
    unzip \
    wget \
    && apt-get clean
COPY . /opt/toolchain/
FROM tool-chain-repo as tool-chain
RUN cd /opt/toolchain \
    && make toolchain
FROM tool-chain
ARG BOARD
RUN cd /opt/toolchain \
    && ln -s toolchain/output/host /opt/gcw0-toolchain \
    && PATH=/opt/gcw0-toolchain/usr/bin:$PATH make -f Makefile.${BOARD} -j4 \
    && cd updaters \
    && ./create_kernel_${BOARD}.sh \
    && ./create_updater_${BOARD}.sh \
    && cd imager_${BOARD} \
    && ./create_sdimage.sh \
    && mkdir /root/output \
    && cp /opt/toolchain/updaters/imager_${BOARD}/images/sd_image.bin /root/output \
    && cp /opt/toolchain/output/${BOARD}-update-* /root/output
