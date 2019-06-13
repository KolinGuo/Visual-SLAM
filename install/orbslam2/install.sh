#!/usr/bin/env bash

test_retval() {
  if [ $? -ne 0 ] ; then
    echo -e "\nFailed to ${*}... Exiting...\n"
    exit 1
  fi
}

# Install Pangolin and other ORBSLAM dependencies
INSTALLPATH="$1"
apt install -y libglew-dev
test_retval "install libglew"
cd $INSTALLPATH
git clone https://github.com/stevenlovegrove/Pangolin pangolin
cd pangolin
mkdir build
cd build && cmake .. && make -j$(nproc) && make install
test_retval "install pangolin"

cd $INSTALLPATH
if [ ! -d "eigen" ] ; then
  wget http://bitbucket.org/eigen/eigen/get/3.3.3.tar.bz2 \
    && bzip2 -d 3.3.3.tar.bz2 && tar -xvf 3.3.3.tar \
    && rm 3.3.3.tar && mv eigen-* eigen
fi
cd eigen && mkdir build
cd build \
  && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=RELEASE .. \
  && make install
test_retval "install eigen"
ln -s $INSTALLPATH/eigen /usr/local/include/eigen
ldconfig

#cd /slamdoom/tmp
# Install ORBSLAM2
#git clone https://github.com/raulmur/ORB_SLAM2.git orbslam2
#cd /slamdoom/tmp/orbslam2
#git config --global user.name "Slamdoom" && git config --global user.email "slamdoom@slam.doom" && git am --signoff < /slamdoom/install/orbslam2/orbslam2_slamdoom.git.patch
#chmod +x build.sh && sleep 1 && ./build.sh
#cp -R /slamdoom/tmp/orbslam2 /slamdoom/libs/orbslam2
