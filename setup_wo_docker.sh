#!/bin/bash 
# Ensure that you have installed tx2-docker and the latest nvidia graphics driver on host!

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"

test_retval() {
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to ${*}... Exiting...\n"
    exit 1
  fi
}

nvpmodel -m0
test_retval "change Jetson power mode"
jetson_clocks    # Enable Jetson TX2 turbo mode: max freq for CPU, GPU, EMC
test_retval "enable Jetson turbo mode"
USAGE="Usage: ./setup_wo_docker.sh\n"

# Echo the set up information
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tSetting Up ORB-SLAM2 Environment Natively\n"
echo -e "################################################################################\n"

# Print usage
echo -e "\n$USAGE\n"

echo -e ".......... Set up will start in 5 seconds .........."
sleep 5

# Building dependencies
######################################
# SECTION 1: Essentials              #
######################################
echo -e "\nBuilding essentials..."
apt update -y && apt install -y --no-install-recommends apt-utils \
  && apt -y upgrade
test_retval "install apt-utils"

apt install -y libblas-dev liblapack-dev libatlas-base-dev gfortran gdb \
  && apt -y upgrade
test_retval "install BLAS and LAPACK"

apt install -y libcanberra-gtk-module pkg-config libfreetype6-dev libpng-dev
test_retval "install matplotlib dependencies"

apt install -y python3 && apt install -y python3-pip \
  && pip3 install wheel numpy scipy matplotlib \
  && apt update -y && apt upgrade -y
test_retval "install Python3, pip3, numpy and scipy"

######################################
# SECTION 2: CV packages             #
######################################
echo -e "\nBuilding opencv3..."
OPENCVSCRIPTPATH="./install/opencv3/install.sh"
chmod +x "$OPENCVSCRIPTPATH" && $OPENCVSCRIPTPATH /usr/local python3
test_retval "install opencv3"

######################################
# SECTION 3: ORB-SLAM2 dependencies  #
######################################
echo -e "\nBuilding ORB-SLAM2 dependencies..."
ORBDEPSCRIPTPATH="./install/orbslam2/install.sh"
chmod +x "$ORBDEPSCRIPTPATH" && $ORBDEPSCRIPTPATH /usr/local/lib
test_retval "install ORB-SLAM2 dependencies"

######################################
# SECTION 4: Final configs           #
######################################
echo -e "\nSetting final configs..."
# set up matplotlibrc file so have Qt5Agg backend by default
if [ ! -f "/root/.matplotlib/matplotlibrc" ] ; then
  mkdir /root/.matplotlib && touch /root/.matplotlib/matplotlibrc && echo "backend: Qt5Agg" >> /root/.matplotlib/matplotlibrc
  test_retval "set up matplotlibrc file"
fi

apt install -y libboost-all-dev
test_retval "install libboost"

######################################
# SECTION 5: Additional Utilities    #
######################################
echo -e "\nBuilding additional utilities..."
apt -y update && apt install -y software-properties-common
test_retval "install software-properties-common"

# add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise universe" \
#   && add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" \
#   && add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse" \
#   && add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse" \
#   && apt update -y
# test_retval "add apt repositories"

apt install -y \
  libavcodec-dev libavformat-dev libavutil-dev libeigen3-dev libglew-dev \
  libgtk2.0-dev libgtk-3-dev libjasper-dev libjpeg-dev libpng-dev \
  libpostproc-dev libswscale-dev libtbb-dev libtiff5-dev libv4l-dev \
  libxvidcore-dev libx264-dev qt5-default zlib1g-dev \
  libgtkglext1-dev libjpeg-dev libavresample-dev libv4l-dev \
  libopenexr-dev cmake python-tk libtbb-dev yasm libfaac-dev \
  libopencore-amrnb-dev libopencore-amrwb-dev \
  libtheora-dev libvorbis-dev libxvidcore-dev \
  libx264-dev libqt4-dev libqt4-opengl-dev \
  sphinx-common libv4l-dev libdc1394-22-dev \
  libavcodec-dev libavformat-dev libswscale-dev \
  libglew-dev libboost-dev libboost-python-dev libboost-serialization-dev \
  htop nano unzip gnuplot ghostscript texlive-extra-utils \
  && apt -y upgrade \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
test_retval "installing additional utilities"

apt -y update && apt install -y --no-install-recommends mesa-utils \
  && rm -rf /var/lib/apt/lists/*
test_retval "installing mesa-utils"

# Echo command to continue building ORBSLAM2
COMMANDTOBUILDFIRST="bash -i ./build.sh && source ~/.bashrc"
COMMANDTOBUILD="./build.sh"
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tCommand to continue building ORBSLAM2 for the first time:\n\t\t${COMMANDTOBUILDFIRST}\n"
echo -e "\tCommand to build ORBSLAM2 after the first time:\n\t\t${COMMANDTOBUILD}\n"
echo -e "################################################################################\n"

