#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# Remove ORBSLAM2_C++11 previous build
echo -e "Removing ORBSLAM2_C++11 previous build"
cd "$SCRIPTPATH"/ORBSLAM2_C++11
rm -rfv build cmake_modules \
        Examples/Monocular/mono_euroc \
        Examples/Monocular/mono_kitti \
        Examples/Monocular/mono_tum \
        Examples/RGB-D/rgbd_tum \
        Examples/Stereo/stereo_euroc \
        Examples/Stereo/stereo_kitti 

# Rebuild ORBSLAM2_C++11
echo -e "\nRebuilding ORBSLAM2_C++11"
chmod +x build.sh
sleep 1
./build.sh

# Remove python wrapper previous build
echo -e "\nRemoving python wrapper previous build"
cd "$SCRIPTPATH"
rm -rfv bin build cmake_modules

# Build python wrapper
echo -e "\nRebuilding python wrapper"
mkdir build
cd build
cmake -DBUILD_PYTHON3=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_MODULE_PATH=/usr/local/include/eigen/cmake \
        -DZMQ_INCLUDE_DIR=/usr/local/include \
        -DZMQ_LIBRARY=/usr/local/lib/libzmq.so \
        -DORBSLAM2_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/lib/libORB_SLAM2.so \
        -DBG2O_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/g2o/lib/libg2o.so \
        -DDBoW2_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/DBoW2/lib/libDBoW2.so \
        ..
echo "export CPATH=/usr/local/include/eigen/:"$SCRIPTPATH"/ORBSLAM2_C++11:/slamdoom/libs/cppzmq:/usr/local/include/" \
        >> ~/.bashrc
echo "export LD_LIBRARY_PATH="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/DBoW2/lib" \
        >> ~/.bashrc
source ~/.bashrc
make -j16
