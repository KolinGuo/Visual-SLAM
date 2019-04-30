FROM nvidia/opengl:1.1-glvnd-runtime-ubuntu16.04

RUN apt-get -y update && apt-get install -y software-properties-common python-software-properties

RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise universe" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse"

RUN apt-get update && apt-get install -y \
        libgtk2.0-dev \
        libjpeg-dev \
        libjasper-dev \
        libopenexr-dev cmake python-dev \
        python-numpy python-tk libtbb-dev \
        libeigen2-dev yasm libfaac-dev \
        libopencore-amrnb-dev libopencore-amrwb-dev \
        libtheora-dev libvorbis-dev libxvidcore-dev \
        libx264-dev libqt4-dev libqt4-opengl-dev \
        sphinx-common libv4l-dev libdc1394-22-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libglew-dev libboost-dev libboost-python-dev libboost-serialization-dev \
        htop nano wget git unzip \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV OPENCV 3.4.6

RUN cd /opt && wget http://bitbucket.org/eigen/eigen/get/3.2.10.tar.gz -O eigen3.tgz \
&& tar zxvf eigen3.tgz && cd  eigen-eigen-b9cd8366d4e8 \
&& mkdir build && cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RELEASE .. \
&& make install \
&& cd /opt && git clone https://github.com/stevenlovegrove/Pangolin.git \
&& cd Pangolin && mkdir build && cd build && cmake  .. \
&& make -j16 && make install \
&& cd /opt && wget https://codeload.github.com/opencv/opencv/zip/$OPENCV -O opencv.zip \
&& unzip opencv.zip \
&& cd opencv-$OPENCV && mkdir build && cd build \
&& cmake -D CMAKE_BUILD_TYPE=RELEASE .. \
&& make -j16 && make install \
&& rm -rf /opt/* && ldconfig

# Nvidia display config
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display

RUN apt-get update && apt-get install -y --no-install-recommends \
        mesa-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root
