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
                elif [ "$1" = "py=0" ] ; then   # Don't build python wrapper
                        BUILDPYTHON=false
                elif [ "$1" = "clean" ] ; then  # Clean previous builds only
                        BUILDCLEAN=true
                        break
                elif [[ "$1" != "c++=0" && "$1" != "py=1" ]] ; then
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
        echo -e "\nNo build will be done, only cleaning\n"
        # Remove ORBSLAM2_C++11 previous build
        echo -e "\nRemoving C++11 previous build..."
        cd "$SCRIPTPATH"/ORBSLAM2_C++11
        rm -rf build lib \
                Thirdparty/DBoW2/build \
                Thirdparty/DBoW2/lib \
                Thirdparty/g2o/build \
                Thirdparty/g2o/lib \
                Thirdparty/g2o/config.h \
                Vocabulary/ORBvoc.txt \
                Examples/Monocular/mono_euroc \
                Examples/Monocular/mono_kitti \
                Examples/Monocular/mono_tum \
                Examples/RGB-D/rgbd_tum \
                Examples/Stereo/stereo_euroc \
                Examples/Stereo/stereo_kitti 

        # Remove python wrapper previous build
        echo -e "\nRemoving Python previous build..."
        cd "$SCRIPTPATH"
        rm -rf bin build
        
        exit 0
fi

# Echo the building information
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tBuilding Information\n"
if [ "$BUILDCPLUSPLUS" = true ] ; then
        echo -e "\t\tBuild C++11 Implementation\n"
fi

if [ "$BUILDPYTHON" = true ] ; then
        echo -e "\t\tBuild Python Implementation\n"
fi

if [[ "$BUILDCPLUSPLUS" = false && "$BUILDPYTHON" = false ]] ; then
        echo -e "\t\tNo build is specified... Exiting...\n"
        echo -e "################################################################################\n"
        echo -e "\n$USAGE\n"
        exit 0
fi
echo -e "################################################################################\n"

# Prints out USAGE
echo -e "\n$USAGE\n"

echo -e ".......... Building will start in 5 seconds .........."
sleep 5

#########################################
#       Start the Build Process         #
#########################################
if [ "$BUILDCPLUSPLUS" = true ] ; then
        # Remove ORBSLAM2_C++11 previous build
        echo -e "\nRemoving C++11 previous build..."
        cd "$SCRIPTPATH"/ORBSLAM2_C++11
        rm -rf build lib \
                Thirdparty/DBoW2/build \
                Thirdparty/DBoW2/lib \
                Thirdparty/g2o/build \
                Thirdparty/g2o/lib \
                Thirdparty/g2o/config.h \
                Vocabulary/ORBvoc.txt \
                Examples/Monocular/mono_euroc \
                Examples/Monocular/mono_kitti \
                Examples/Monocular/mono_tum \
                Examples/RGB-D/rgbd_tum \
                Examples/Stereo/stereo_euroc \
                Examples/Stereo/stereo_kitti 
        
        # Rebuild ORBSLAM2_C++11
        echo -e "\nBuilding C++11 Implementation..."
        chmod +x build.sh
        ./build.sh
        if [ $? -ne 0 ] ; then
                echo -e "\nFailed to build C++11 Implementation... Exiting...\n"
                exit 1
        fi
fi

if [ "$BUILDPYTHON" = true ] ; then
        # Remove python wrapper previous build
        echo -e "\nRemoving Python previous build..."
        cd "$SCRIPTPATH"
        rm -rf bin build
        
        # Build python wrapper
        echo -e "\nBuilding Python Implementation..."
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

        if [ $? -ne 0 ] ; then
                echo -e "\nFailed to cmake Python Implementation... Exiting...\n"
                exit 1
        fi
        
        # If it's the first time build, add environment variable
        if [ -z $ORBSLAM2PYFIRSTBUILD ] ; then
                echo "export CPATH=/usr/local/include/eigen/:"$SCRIPTPATH"/ORBSLAM2_C++11:/slamdoom/libs/cppzmq:/usr/local/include/" \
                        >> ~/.bashrc
                echo "export LD_LIBRARY_PATH="$SCRIPTPATH"/ORBSLAM2_C++11/Thirdparty/DBoW2/lib" \
                        >> ~/.bashrc
                source ~/.bashrc
        fi
        make -j$(nproc)

        if [ $? -ne 0 ] ; then
                echo -e "\nFailed to make Python Implementation... Exiting...\n"
                exit 1
        fi
fi

# If it's the first time build, include into PYTHONPATH
if [ -z $ORBSLAM2PYFIRSTBUILD ] ; then
        echo "export PYTHONPATH=$SCRIPTPATH/build:$PYTHONPATH" \
                >> ~/.bashrc
        echo "export ORBSLAM2PYFIRSTBUILD=false" \
                >> ~/.bashrc
        source ~/.bashrc
fi

# Echo command to run example
COMMANDTORUNCPLUSPLUS="\t\tcd ORBSLAM2_C++11/Examples/Stereo/KITTI_Dataset\n"
COMMANDTORUNCPLUSPLUS+="\t\t./download_kitti_dataset.sh\n"
COMMANDTORUNCPLUSPLUS+="\t\tcd ..\n"
COMMANDTORUNCPLUSPLUS+="\t\t./stereo_kitti ../../Vocabulary/ORBvoc.txt ./KITTIX.yaml \\ \n"
COMMANDTORUNCPLUSPLUS+="\t\t\t./KITTI_Dataset/dataset/sequences/SEQUENCE_NUMBER\n"
COMMANDTORUNPYTHON="\t\tpython3 test/test.py\n"
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tCommmand to run ORBSLAM2 C++11 Implementation:\n"\
        "${COMMANDTORUNCPLUSPLUS}"\
        "\tCommand to run ORBSLAM2 Python Implementation:\n"\
        "${COMMANDTORUNPYTHON}"
echo -e "################################################################################\n"

