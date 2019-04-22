# Notes on ORB-SLAM Paper
## System Overview
1. Feature Choice  
* **Same features** used by the mapping and tracking are used for 
place recognition to perform frame-rate relocalization and loop 
detection. 
* ORB: *oriented multi-scale FAST corners with a 256 bits descriptor
 associated*. Extremely fast to compute and match, while having 
**good invariance to viewpoint**.  
* To obtain general place recognition capabilities, we require 
rotation invariance, which excludes BRIEF and LDB. 
2. Three Threads: Tracking, Local Mapping and Loop Closing
* Tracking: localizes the camera with every frame and decides when 
to insert a new keyframe.  
* Local Mapping: processes new keyframes and performs local BA to 
achieve an optimal reconstruction in the surroundings of the camera 
pose.
* Loop Closing: searches for loops with every new keyframe.  
3. Map Points, KeyFrames and their Selection  
* Each map point $p_{i}$ stores:   
    * Its 3D position $\bm{X}_{w,i}$ in the world coordinate system. 
    * The viewing direction $\bm{n}_i$, which is the mean unit vector
of all its viewing directions (the rays that join the point with the
optical center of the keyframes that observe it). 
    * A representative ORB descriptor $\bm{D}_i$, which is the 
associated descriptors in the keyframes in which the point is 
observed. 
    * The maximum $d_{max}$ and minimum $d_{min}$ distances at which 
the point can be observed, according to the scale invariance limits
of the ORB features. 

* Each keyframe $K_{i}$ stores: 
    * The camera pose $\bm{T}_{iw}$, which is a rigid body 
transformation that transforms points from the world to the camera 
coordinate system. 
    * The camera intrinsics, including focal length and principal 
point. 
    * All the ORB features extracted in the frame, associated or not 
to a map point, whose coordinates are undistorted if a distortion 
model is provided.  
4. *Covisibility Graph* and *Essential Graph*  
* *Covisibility Graph*:  
An **undirected weighted** graph. Each **node** is a **keyframe** 
and an **edge** between two keyframes exists if they **share 
observations of the same map points** (at least 15). The **weight** 
$\theta$ of the edge is the **number of common map points**. 

* *Essential Graph*: retains **all the nodes** (keyframes), but 
**less edges**, still preserving a strong network that yields 
accurate results.  
The system builds incrementally a *spanning tree* from the initial
keyframe, which provides a **connected subgraph of the covisibility
graph with minimal number of edges**.  
The *Essential Graph* contains 
    * the *spanning tree*
    * the subset of edges from the *covisibility graph* with high
covisibility ($\theta_{min} = 100$)
    * the loop closure edges
5. *Bags of Words Place Recognition*


## Map Initialization

## Tracking

## Local Mapping

## Loop Closing

