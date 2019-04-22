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
## Map Initialization

## Tracking

## Local Mapping
1. KeyFrame Insertion
* Update the covisibility graph
* Add a new node for * **Ki** *
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

