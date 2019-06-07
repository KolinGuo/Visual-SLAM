#!/bin/bash 
# Ensure that you have installed tx2-docker and the latest nvidia graphics driver on host!

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
nvpmodel -m0
~/jetson_clocks.sh    # Enable Jetson TX2 turbo mode: max freq for CPU, GPU, EMC
USAGE="Usage: ./setup.sh [rmimcont=[0,1]] [rmimg=[0,1]]\n"
USAGE+="\trmimcont=[0,1] : 0 to not remove intermediate Docker containers\n"
USAGE+="\t                 after a successful build and 1 otherwise\n"
USAGE+="\t                 default is 1\n"
USAGE+="\trmimg=[0,1]    : 0 to not remove previously built Docker image\n"
USAGE+="\t                 and 1 otherwise\n"
USAGE+="\t                 default is 0\n"
IMGNAME="orbslam2py"
CONTNAME="orbslam2py"

REMOVEIMDDOCKERCONTAINERCMD="--rm=true"
REMOVEPREVDOCKERIMAGE=false

# Parsing argument
if [ $# -ne 0 ] ; then
        while [ ! -z $1 ] ; do
                if [ "$1" = "rmimcont=0" ] ; then
                        REMOVEIMDDOCKERCONTAINERCMD="--rm=false"
                elif [ "$1" = "rmimg=1" ] ; then
                        REMOVEPREVDOCKERIMAGE=true
                elif [[ "$1" != "rmimcont=1" && "$1" != "rmimg=0" ]] ; then
                        echo -e "Unknown argument: " $1
                        echo -e "$USAGE"
                        exit 1
                fi
                shift
        done
fi

# Echo the set up information
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tSet Up Information\n"
if [ "$REMOVEIMDDOCKERCONTAINERCMD" = "--rm=true" ] ; then
        echo -e "\t\tRemove intermediate Docker containers after a successful build\n"
else
        echo -e "\t\tKeep intermediate Docker containers after a successful build\n"
fi
if [ "$REMOVEPREVDOCKERIMAGE" = true ] ; then
        echo -e "\t\tCautious!! Remove previously built Docker image\n"
else
        echo -e "\t\tKeep previously built Docker image\n"
fi
echo -e "################################################################################\n"

# Print usage
echo -e "\n$USAGE\n"

echo -e ".......... Set up will start in 5 seconds .........."
sleep 5

# Remove previously built Docker image
if [ "$REMOVEPREVDOCKERIMAGE" = true ] ; then
        echo -e "\nRemoving previously built image..."
        tx2-docker rmi -f $IMGNAME
fi

# Build and run the image
echo -e "\nBuilding image..."
tx2-docker build $REMOVEIMDDOCKERCONTAINERCMD -t $IMGNAME .

if [ $? -ne 0 ] ; then
        echo -e "\nFailed to build Docker image... Exiting...\n"
        exit 1
fi

# Build a container from the image
echo -e "\nRemoving older container..."
if [ 1 -eq $(docker container ls -a | grep "$CONTNAME$" | wc -l) ] ; then
	tx2-docker rm -f $CONTNAME
fi

echo -e "\nBuilding a container from the image..."
tx2-docker create -it --name=$CONTNAME \
	      -v "$SCRIPTPATH":/root/Visual-SLAM \
	      -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v /media/nvidia/Samsung_T5:/media/nvidia/Samsung_T5 \
        --device=/dev/video0 \
        --device=/dev/video1 \
        --device=/dev/video2 \
        -e DISPLAY=$DISPLAY \
        --cpus="6" \
	      $IMGNAME /bin/bash

if [ $? -ne 0 ] ; then
        echo -e "\nFailed to create Docker container... Exiting...\n"
        exit 1
fi

# Echo command to continue building ORBSLAM2
COMMANDTOBUILDFIRST="cd /root/Visual-SLAM && bash -i ./build.sh && source ~/.bashrc"
COMMANDTOBUILD="cd /root/Visual-SLAM && ./build.sh"
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tCommand to continue building ORBSLAM2 for the first time:\n\t\t${COMMANDTOBUILDFIRST}\n"
echo -e "\tCommand to build ORBSLAM2 after the first time:\n\t\t${COMMANDTOBUILD}\n"
echo -e "################################################################################\n"

tx2-docker start -ai $CONTNAME

if [ 0 -eq $(docker container ls -a | grep "$CONTNAME$" | wc -l) ] ; then
        echo -e "\nFailed to start/attach Docker container... Exiting...\n"
        exit 1
fi

# Echo command to start container
COMMANDTOSTARTCONTAINER="tx2-docker start -ai $CONTNAME"
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tCommand to start Docker container:\n\t\t${COMMANDTOSTARTCONTAINER}\n"
echo -e "################################################################################\n"

