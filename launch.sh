#!/bin/bash

set -e

echo "Sourcing ..."
source /opt/ros/humble/setup.bash
source /nav2gps_ws/install/setup.bash

echo "Launching Nav2 GPS Waypoint Follower with RViz..."
ros2 launch nav2_gps_waypoint_follower_demo gps_waypoint_follower.launch.py use_rviz:=True