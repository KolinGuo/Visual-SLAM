#!/bin/bash 
# Ensure that you have installed nvidia-docker and the latest nvidia graphics driver on host!

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
USAGE="Usage: ./setup.sh [rm=[0,1]]\n"
USAGE+="\trm=[0,1] : 0 to remove intermediate Docker images after a successful build and 1 otherwise\n"
USAGE+="\t           default is 0\n"

REMOVEDOCKERIMAGE=false

# Parsing argument
if [ $# -ne 0 ] ; then
        if [ "$1" = "rm=1" ] ; then
                REMOVEDOCKERIMAGE=true
        elif [ "$1" != "rm=0" ] ; then
                echo -e "UNknown argument: " $1
                echo -e "$USAGE"
                exit 1
        fi
fi

# Echo the set up information
if [ "$REMOVEDOCKERIMAGE" = true ] ; then
        echo -e "Remove all intermediate Docker images after a successful build"
fi

# Print usage
echo -e "\n$USAGE"
echo -e ".......... Set up will start in 5 seconds .........."
sleep 5

# Build and run the image
echo -e "\nBuilding image..."
nvidia-docker build --rm=true -t orbslam2py .

# Remove intermediate Docker images
if [[ "$REMOVEDOCKERIMAGE" = true && $? -eq 0 ]] ; then
        echo -e "\nRemoving intermediate images..."
        DOCKERIMAGES=$(docker images | grep "<none>" | \
                sort -n -r -k4,4 | egrep -oh '[[:alnum:]]{12}')
        for image in $DOCKERIMAGES ; do
                echo -e "Removing image" $image
                docker rmi -f $image
        done
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

nvidia-docker start -ai orbslam2py

# Echo command to start container
COMMANDTOSTARTCONTAINER="nvidia-docker start -ai orbslam2py"
echo -e "\nCommand to start Docker container:\n\t${COMMANDTOSTARTCONTAINER}\n"
