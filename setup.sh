#!/bin/bash 
# Ensure that you have installed nvidia-docker and the latest nvidia graphics driver on host!

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
USAGE="Usage: ./setup.sh [rmimcont=[0,1]] [rmimg=[0,1]]\n"
USAGE+="\trmimcont=[0,1] : 0 to not remove intermediate Docker containers\n"
USAGE+="\t                 after a successful build and 1 otherwise\n"
USAGE+="\t                 default is 1\n"
USAGE+="\trmimg=[0,1]    : 0 to not remove previously built Docker image\n"
USAGE+="\t                 and 1 otherwise\n"
USAGE+="\t                 default is 1\n"

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
                        echo -e "UNknown argument: " $1
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
        nvidia-docker rmi -f orbslam2py
fi

# Build and run the image
echo -e "\nBuilding image..."
nvidia-docker build $REMOVEIMDDOCKERCONTAINERCMD -t orbslam2py .

if [ $? -ne 0 ] ; then
        echo -e "\nFailed to build Docker image... Exiting...\n"
        exit 1
fi

# Build a container from the image
echo -e "\nRemoving older container..."
if [ 1 -eq $(docker container ls -a | grep "orbslam2py$" | wc -l) ] ; then
	nvidia-docker rm -f orbslam2py
fi

echo -e "\nBuilding a container from the image..."
nvidia-docker create -it --name=orbslam2py \
	-v "$SCRIPTPATH":/root/Visual-SLAM \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=$DISPLAY \
	orbslam2py /bin/bash

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

nvidia-docker start -ai orbslam2py

if [ 0 -eq $(docker container ls -a | grep "orbslam2py$" | wc -l) ] ; then
        echo -e "\nFailed to start/attach Docker container... Exiting...\n"
        exit 1
fi

# Echo command to start container
COMMANDTOSTARTCONTAINER="nvidia-docker start -ai orbslam2py"
echo -e "\n\n"
echo -e "################################################################################\n"
echo -e "\tCommand to start Docker container:\n\t\t${COMMANDTOSTARTCONTAINER}\n"
echo -e "################################################################################\n"

