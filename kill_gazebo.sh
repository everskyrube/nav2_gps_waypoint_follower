#!/bin/bash

echo "🔪 Terminating hanging Gazebo processes..."

# Force kill Gazebo Classic processes (standard for ROS 2 Humble)
killall -9 gzserver gzclient 2>/dev/null

# Catch any stray Python nodes matching 'gazebo' in their execution string
pkill -9 -f gazebo 2>/dev/null

# Clean up any ROS 2 launch files that might be stuck waiting for Gazebo
pkill -9 -f ros2_launch 2>/dev/null

echo "✅ Gazebo processes successfully cleared."