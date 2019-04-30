# Visual-SLAM
EEC 193AB Independent Senior Design Project 2018-2019 @ UC-Davis

## Group Members 
  * Kolin Guo
  * Jeff Lai
  * Wenda Xu
  
## Teaching Assistants
  * Teja Aluru
  * Adam Jones
  * Minh Truong
  
## Instructions on Setting up Docker Image and Container
1. Build a Docker image using the Dockerfile under Docker/ with the following command:  
`sudo docker build -t orb_slam2 .`
2. Create a container from the image with the following command:  
`sudo nvidia-docker create -it --name=orb_slam2 -v "[path_to_this_repo]/Visual-SLAM":/root/Visual-SLAM -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY orb_slam2 /bin/bash`  

Note: If you only have an Nvidia GPU and no integrated graphics, you will need to install `nvidia-docker` via the instructions [here](https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0)). 

## Notes
  * The testing/benchmarking environment of the original ORB_SLAM2 C++ implementation is the **Benchmark** branch. We avoid benchmarking in the **master** branch to keep it tidy. All benchmark results will be summarized and uploaded to **master** branch. 
