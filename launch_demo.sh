source /nav2gps_ws/install/setup.bash
# ros2 run nav2_gps_waypoint_follower_demo logged_waypoint_follower </path/to/yaml/file.yaml>
# If the path is empty, the default waypoints found in config/demo_waypoints.yaml will be used
ros2 run nav2_gps_waypoint_follower_demo logged_waypoint_follower /nav2gps_ws/nav2_gps_waypoint_follower_demo/config/demo_waypoints.yaml
