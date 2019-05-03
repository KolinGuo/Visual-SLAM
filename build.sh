#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
USAGE="Usage: ./build.sh [c++=[0,1]] [py=[0,1]] [clean]\n"
USAGE+="\tc++=[0,1] : 0 to not build ORBSLAM2 C++11 implementation and 1 otherwise\n"
USAGE+="\t            default is 0\n"
USAGE+="\tpy=[0,1]  : 0 to not build ORBSLAM2 Python implementation and 1 otherwise\n"
USAGE+="\t            default is 1\n"
USAGE+="\tclean     : clean both C++11 and Python previous build and don't rebuild\n"

#########################################
#        Configurate the Build          #
#########################################
# If no arguments, build only python wrapper by default
BUILDCPLUSPLUS=false
BUILDPYTHON=true

# Parsing command-line arguments
# If it's the first time build, build both C++ and python wrapper
if [ -z $ORBSLAM2PYFIRSTBUILD ] ; then
        BUILDCPLUSPLUS=true
        BUILDPYTHON=true
# If there are arguments, parse all arguments
elif [ $# -ne 0 ] ; then
        while [ ! -z $1 ] ; do
                if [ "$1" = "c++=1" ] ; then    # Build C++ 
                        BUILDCPLUSPLUS=true
                elif [ "$1" = "c++=0" ]; then   # Don't build C++
                        BUILDCPLUSPLUS=false
                elif [ "$1" = "py=1" ] ; then   # Build python wrapper
                        BUILDPYTHON=true
                elif [ "$1" = "py=0" ] ; then   # Don't build python wrapper
                        BUILDPYTHON=false
                elif [ "$1" = "clean" ] ; then  # Clean previous builds only
                        BUILDCLEAN=true
                        break
                else
                        echo -e "Unknown argument: " $1
                        echo -e "$USAGE"
                        exit 1
                fi
                shift   # shift $2 to $n to be renamed $1 to $(n-1)
        done
fi

#########################################
#       Start the Clean Process         #
#########################################
if [ "$BUILDCLEAN" = true ] ; then
        echo -e "No build will be done, only cleaning"
        # Remove ORBSLAM2_C++11 previous build
        echo -e "\nRemoving C++11 previous build"
        cd "$SCRIPTPATH"/ORBSLAM2_C++11
        rm -rf build \
                Thirdparty/DBoW2/build \
                Thirdparty/g2o/build \
                Vocabulary/ORBvoc.txt \
                Examples/Monocular/mono_euroc \
                Examples/Monocular/mono_kitti \
                Examples/Monocular/mono_tum \
                Examples/RGB-D/rgbd_tum \
                Examples/Stereo/stereo_euroc \
                Examples/Stereo/stereo_kitti 

        # Remove python wrapper previous build
        echo -e "\nRemoving Python previous build"
        cd "$SCRIPTPATH"
        rm -rf bin build
        
        exit 0
fi

# Echo the building information
if [ "$BUILDCPLUSPLUS" = true ] ; then
        echo -e "Building C++11 Implementation"
fi

if [ "$BUILDPYTHON" = true ] ; then
        echo -e "Building Python Implementation"
fi

if [[ "$BUILDCPLUSPLUS" = false && "$BUILDPYTHON" = false ]] ; then
        echo -e "No build is specified\nExiting"
        echo -e "$USAGE"
        exit 0
fi

# Prints out USAGE
echo -e "\n$USAGE"

echo -e ".......... Building will start in 5 seconds .........."
sleep 5

#########################################
#       Start the Build Process         #
#########################################
if [ "$BUILDCPLUSPLUS" = true ] ; then
        # Remove ORBSLAM2_C++11 previous build
        echo -e "Removing C++11 previous build"
        cd "$SCRIPTPATH"/ORBSLAM2_C++11
        rm -rf build \
                Thirdparty/DBoW2/build \
                Thirdparty/g2o/build \
                Vocabulary/ORBvoc.txt \
                Examples/Monocular/mono_euroc \
                Examples/Monocular/mono_kitti \
                Examples/Monocular/mono_tum \
                Examples/RGB-D/rgbd_tum \
                Examples/Stereo/stereo_euroc \
                Examples/Stereo/stereo_kitti 
        
        # Rebuild ORBSLAM2_C++11
        echo -e "\nBuilding C++11 Implementation"
        chmod +x build.sh
        sleep 1
        ./build.sh
fi

if [ "$BUILDPYTHON" = true ] ; then
        # Remove python wrapper previous build
        echo -e "\nRemoving Python previous build"
        cd "$SCRIPTPATH"
        rm -rf bin build
        
        # Build python wrapper
        echo -e "\nBuilding Python Implementation"
        mkdir build
        cd build
        cmake -DBUILD_PYTHON3=ON \
                -DCMAKE_BUILD_TYPE=Release \
                -DZMQ_INCLUDE_DIR=/usr/local/include \
                -DZMQ_LIBRARY=/usr/local/lib/libzmq.so \
                -DORBSLAM2_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/lib/libORB_SLAM2.so \
                -DBG2O_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/g2o/lib/libg2o.so \
                -DDBoW2_LIBRARY="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/DBoW2/lib/libDBoW2.so \
                ..
        
        # If it's the first time build, add environment variable
        if [ -z $ORBSLAM2PYFIRSTBUILD ] ; then
                echo "export CPATH=/usr/local/include/eigen/:"$SCRIPTPATH"/ORBSLAM2_C++11:/slamdoom/libs/cppzmq:/usr/local/include/" \
                        >> ~/.bashrc
                echo "export LD_LIBRARY_PATH="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/DBoW2/lib" \
                        >> ~/.bashrc
                source ~/.bashrc
        fi
        make -j16
fi

# If it's the first time build, include into PYTHONPATH
if [ -z $ORBSLAM2PYFIRSTBUILD ] ; then
        echo "export PYTHONPATH=$SCRIPTPATH/build:$PYTHONPATH" \
                >> ~/.bashrc
        echo "export ORBSLAM2PYFIRSTBUILD=false" \
                >> ~/.bashrc
        source ~/.bashrc
fi

