# FROM defines the base image
# FROM ubuntu16.04
# FROM ubuntu:latest
FROM nvidia/cudagl:10.1-devel-ubuntu16.04

######################################
# SECTION 1: Essentials              #
######################################

#Update apt-get and upgrade
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils # Fix 
RUN apt-get -y upgrade

#Install python3 pip3
RUN apt-get -y install python3
RUN apt-get -y install python3-pip
RUN pip3 install pip --upgrade
RUN pip3 install numpy scipy

#Install python2.7  pip
RUN apt-get -y install python2.7 wget
RUN wget https://bootstrap.pypa.io/get-pip.py && python2.7 get-pip.py
RUN pip install pip --upgrade
RUN pip install numpy scipy

# set up directories
RUN mkdir /slamdoom
RUN mkdir /slamdoom/tmp
RUN mkdir /slamdoom/libs

RUN apt-get update -y

######################################
# SECTION 2: CV packages             #
######################################

### -------------------------------------------------------------------
### install OpenCV 3 with python3 bindings and CUDA 8
### -------------------------------------------------------------------
ADD ./install/opencv3 /slamdoom/install/opencv3
RUN chmod +x /slamdoom/install/opencv3/install.sh && /slamdoom/install/opencv3/install.sh /slamdoom/libs python3

#### -------------------------------------------------------------------
#### Install ORBSLAM2
#### -------------------------------------------------------------------
ADD ./install/orbslam2 /slamdoom/install/orbslam2
RUN chmod +x /slamdoom/install/orbslam2/install.sh && /slamdoom/install/orbslam2/install.sh

############################################
## SECTION: Additional libraries and tools #
############################################

RUN apt-get install -y vim

############################################
## SECTION: Final instructions and configs #
############################################

RUN apt-get install -y libcanberra-gtk-module
RUN pip install matplotlib

# set up matplotlibrc file so have Qt5Agg backend by default
RUN mkdir /root/.matplotlib && touch /root/.matplotlib/matplotlibrc && echo "backend: Qt5Agg" >> /root/.matplotlib/matplotlibrc
RUN apt-get install -y gdb

RUN apt-get install -y libboost-all-dev
RUN pip install numpy --upgrade
RUN pip3 install numpy --upgrade

# Fix some linux issue
ENV DEBIAN_FRONTEND teletype

######################################
## SECTION: Additional Utilities     #
######################################

RUN apt-get -y update && apt-get install -y software-properties-common python-software-properties

RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise universe" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse" && \
    add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse"

RUN apt-get update && apt-get install -y \
        libgtk2.0-dev \
        libjpeg-dev \
        libjasper-dev \
        libopenexr-dev cmake \
	python-tk libtbb-dev \
        libeigen2-dev yasm libfaac-dev \
        libopencore-amrnb-dev libopencore-amrwb-dev \
        libtheora-dev libvorbis-dev libxvidcore-dev \
        libx264-dev libqt4-dev libqt4-opengl-dev \
        sphinx-common libv4l-dev libdc1394-22-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libglew-dev libboost-dev libboost-python-dev libboost-serialization-dev \
        htop nano unzip \
&& apt-get -y upgrade \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Nvidia display config
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES},display

RUN apt-get update && apt-get install -y --no-install-recommends \
        mesa-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

