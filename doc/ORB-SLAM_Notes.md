# Notes on ORB-SLAM Paper
## System Overview
1. Feature Choice  
* **Same features** used by the mapping and tracking are used for place 
recognition to perform frame-rate relocalization and loop detection. 
* ORB: *oriented multi-scale FAST corners with a 256 bits descriptor 
associated*. Extremely fast to compute and match, while having **good 
invariance to viewpoint**.  
* To obtain general place recognition capabilities, we require rotation 
invariance, which excludes BRIEF and LDB. 
2. Three Threads: Tracking, Local Mapping and Loop Closing
* Tracking: localizes the camera with every frame and decides when to insert 
a new keyframe.  
* Local Mapping: processes new keyframes and performs local BA to achieve an 
optimal reconstruction in the surroundings of the camera pose.
* Loop Closing: searches for loops with every new keyframe.  
3. Map Points, KeyFrames and their Selection  
* Each map point $p_{i}$ stores:   
    * Its 3D position $\bm{X}_{w,i}$ in the world coordinate system. 
    * The viewing direction $\bm{n}_i$, which is the mean unit vector of all 
its viewing directions (the rays that join the point with the optical center 
of the keyframes that observe it). 
    * A representative ORB descriptor $\bm{D}_i$, which is the associated 
descriptors in the keyframes in which the point is observed. 
    * The maximum $d_{max}$ and minimum $d_{min}$ distances at which the point 
can be observed, according to the scale invariance limits of the ORB features. 

* Each keyframe $K_{i}$ stores: 
    * The camera pose $\bm{T}_{iw}$, which is a rigid body transformation that 
transforms points from the world to the camera coordinate system. 
    * The camera intrinsics, including focal length and principal point. 
    * All the ORB features extracted in the frame, associated or not to a map 
point, whose coordinates are undistorted if a distortion model is provided.  
4. *Covisibility Graph* and *Essential Graph*  
* *Covisibility Graph*:  
An **undirected weighted** graph. Each **node** is a **keyframe** and an 
**edge** between two keyframes exists if they **share observations of the same 
map points** (at least 15). The **weight** $\theta$ of the edge is the **number 
of common map points**. 

* *Essential Graph*: retains **all the nodes** (keyframes), but **less edges**, 
still preserving a strong network that yields accurate results.  
The system builds incrementally a *spanning tree* from the initial keyframe, 
which provides a **connected subgraph of the covisibility graph with minimal 
number of edges**.  
The *Essential Graph* contains 
    * the *spanning tree*
    * the subset of edges from the *covisibility graph* with high covisibility 
($\theta_{min} = 100$)
    * the loop closure edges
5. *Bags of Words Place Recognition*  
Performs loop detection and relocalization. 
* Visual words: a discretization of the descriptor space (**visual 
vocabulary**).  
The vocabulary is created offline with the **ORB descriptors extracted from a 
large set of images**.  
The system builds incrementally a database that contains an invert index, which 
stores for each visual word in the vocabulary, in **which keyframes it has been 
seen**. 

## Map Initialization

## Tracking
ORB extraction 
- extract FAST corners. The orientation and **ORB descriptor** are then 
computed on the retained FAST coners. (ORB descriptor is used in all feature 
matching).

Initial Pose Estimation from previous frame 
- If tracking  in last frame is successful:
    1. use contant velocity model to predict the camera pose and perform 
       a guided search of the map points observed in the last frame. 
    2. If not enough matches were found, use a wider search of the map points
       around their position in the last frame.

Initial Pose Estimation via global relocalization 
- If the tracking is lost:
    1. Convert the frame into **bag of words** and query the recognition 
       database for keyframe candidates for global relocalization. 
    2. Compute associated map points in each keyframe. 
    3. **RANSAC** iterations for each keyframe and try to find a camera pose.
    4. Optimize the pose and perform a guided search of more matches with the 
       map points of the candidate keyframe.

Track Local map 
- Based on our estimation of the camera pose and an initial set of feature 
matches, we can project the map into the frame and search more map points. 
As a complexity issue, we only project a local map. This local map contains the 
set of keyframes K1 (share map points with current frame). A set K2 with 
neighbors to the keyframe K1 in the convisibility graph.

   1) Compute the map point projection x in the current frame.
   2) Compute the angle between the current viewing ray v and the map point 
      mean viewing direction n.
   3) Compute the distance d from map point to camera center. 
   4) Compute the scale in the frame by the ratio d/dmin.
   5) Compare the **representative descriptor D** of the map point with the 
      still unmatched ORB features in the frame, at the predicted scale and 
      near x, and associate the map point with the best match.

After this step, the camera pose is finally optimized with all the map points 
found in the frame

New Keyframe Decision 
- Decide if the current frame is spawned as a new keyframe.

  Contions met to insert a new keyframe:
    1) More than 20 frames must have passed from the last global relocalization.
    2) Local mapping is idle, or more than 20 frames have passed from the last 
       keyframe insertion.
    3) Current frame tracks at least 50 points.
    4) Current frame tracks less than 90% points than Kref.

## Local Mapping
1. KeyFrame Insertion
* Update the covisibility graph
* Add a new node for **Ki** 
* Update the edges resulting from the shared map points with
**other keyframes** 
* Update the spanning tree linking **Ki** with keyframes with most
points in common
* Compute BOG for triangulating new points
2. Recent Map points Culling
* Map points need to pass a test to be retained in the map
* Satisfy two conditions: 1) The tracking must find the point in more
than 25% of the frames; 2) It must be observed from at least three frames
* Once it passes, it can only be removed when observed less than 3 keyframes
3. New Map Point Creation
* New map points are created by triangulating ORB from connected keyframes
in the covisibility graph
* **For each unmatched point**, search a match with other unmatched point in 
other keyframe
4. Local Bundle Adjustment
* BA optimizes the currently possessed keyframe **Ki**, all the keyframes 
connected to it in the covisibility graph and all the map points seen by those
keyframes
5. Local Keyframe Culling
* Detect redundant keyframes and delete them
* Discard all the keyframes whose 90% of the map points have been seen in at 
least other three keyframes in the same or finer scale 
## Loop Closing



