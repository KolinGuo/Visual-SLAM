# Download dataset
echo -e "Downloading stereo odometry data set (grayscale, 22 GB)"
wget -c https://s3.eu-central-1.amazonaws.com/avg-kitti/data_odometry_gray.zip

echo -e "\nUnzipping dataset"
unzip data_odometry_gray.zip -d ./

echo -e "\nRemove zip file"
rm -rfv data_odometry_gray.zip

# Download ground truth poses
echo -e "\nDownloading stereo odometry ground truth poses (4 MB)"
wget -c https://s3.eu-central-1.amazonaws.com/avg-kitti/data_odometry_poses.zip

echo -e "\nUnzipping ground truth poses"
unzip -q data_odometry_poses.zip -d ./

echo -e "\nRemove zip file"
rm -rfv data_odometry_poses.zip

# Download development kit
echo -e "\nDownloading odometry development kit"
wget -c https://s3.eu-central-1.amazonaws.com/avg-kitti/devkit_odometry.zip

echo -e "\nUnzipping odometry dev kit"
unzip -q devkit_odometry.zip -d ./

echo -e "\nRemove zip file"
rm -rfv devkit_odometry.zip
