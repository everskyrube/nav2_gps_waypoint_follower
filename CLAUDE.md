# Nav2 GPS Waypoint Follower - Project Context

## Overview
ROS 2 Humble project for autonomous navigation using GPS (GNSS) localization. This project replicates the official Navigation2 GPS tutorial, demonstrating how to fuse GPS data with odometry/IMU using `robot_localization`, visualize the robot on satellite imagery via `mapviz`, and use Nav2 to follow GPS waypoints with a simulated Turtlebot3.

## 🛑 Execution Rules & Boundaries
* **DO NOT BUILD:** Never execute `colcon build`, `make`, `catkin_make`, or any compilation commands under any circumstances.
* **DO NOT RUN:** Never execute `ros2 launch`, `ros2 run`, or any test scripts. 
* **Manual Verification Only:** I will handle all building, sourcing, and testing locally on my host machine. 
* **Your Role:** Your task is strictly limited to writing, editing, and analyzing code. Assume all code modifications will be tested by me.

## Environment
- **ROS distro**: Humble Hawksbill
- **Robot**: Turtlebot3 Waffle GPS (custom model with GPS sensor added)
- **Simulator**: Gazebo Classic 11.10.2
- **World**: Sonoma Raceway (`sonoma_raceway.world`) — spawns robot at `(2, -2.5, 0.3)`
- **Primary Tools**: Nav2, `robot_localization`, `mapviz`, `nav2_simple_commander`
- **Workspace**: `/nav2gps_ws/` (mounted in Docker container)
- **Docker image**: `everskyrube/navis-ros2-humble:latest` — run via `docker/run.sh`
- **Package**: `nav2_gps_waypoint_follower_demo` (source at `/nav2gps_ws/nav2_gps_waypoint_follower_demo/`)

## Package Structure
```
nav2_gps_waypoint_follower_demo/
├── config/
│   ├── dual_ekf_navsat_params.yaml   # EKF + NavSat fusion config
│   ├── nav2_no_map_params.yaml       # Nav2 params (no pre-built map)
│   ├── demo_waypoints.yaml           # GPS waypoints for logged follower
│   └── gps_sky_demo.mvc             # Mapviz config (OpenStreetMap)
├── launch/
│   ├── gazebo_gps_world.launch.py    # Gazebo + robot_state_publisher
│   ├── dual_ekf_navsat.launch.py     # EKF nodes + navsat_transform
│   ├── gps_waypoint_follower.launch.py  # Master launch (all-in-one)
│   └── mapviz.launch.py             # Mapviz + initialize_origin
├── models/turtlebot_waffle_gps/
│   └── model.sdf                    # Custom TB3 Waffle with GPS sensor
├── urdf/turtlebot3_waffle_gps.urdf  # Robot description for TF
├── worlds/sonoma_raceway.world      # Gazebo world file
└── nav2_gps_waypoint_follower_demo/
    ├── interactive_waypoint_follower.py  # Mapviz click → goToPose
    ├── logged_waypoint_follower.py       # YAML waypoints → followWaypoints
    └── utils/gps_utils.py
```

## How to Launch
```bash
# Inside Docker container — always source both before launching:
source /opt/ros/humble/setup.bash
source /nav2gps_ws/install/setup.bash
export GAZEBO_MODEL_PATH=/nav2gps_ws/install/nav2_gps_waypoint_follower_demo/share/nav2_gps_waypoint_follower_demo/models:/opt/ros/humble/share/turtlebot3_gazebo/models:$HOME/.gazebo/models

# Full launch with Mapviz + interactive waypoint follower (click to navigate):
ros2 launch nav2_gps_waypoint_follower_demo gps_waypoint_follower.launch.py use_mapviz:=true

# Full launch with RViz only:
ros2 launch nav2_gps_waypoint_follower_demo gps_waypoint_follower.launch.py use_rviz:=true

# Run logged waypoint follower (YAML file → auto navigate):
ros2 run nav2_gps_waypoint_follower_demo logged_waypoint_follower
```

## Architecture — How It Works
```
Gazebo sensors → /odom, /imu, /gps/fix
                       │
              robot_localization
          ┌────────────┴────────────┐
  ekf_filter_node_odom      ekf_filter_node_map
  (odom + IMU → odom TF)    (odom + GPS + IMU → map TF)
          └────────────┬────────────┘
               navsat_transform
           (GPS → odometry/gps → /fromLL service)
                       │
                   Nav2 Stack
                       │
         interactive_waypoint_follower
         (Mapviz click → /fromLL → goToPose)
```

**TF tree**: `map → odom → base_footprint → base_link → sensors`

## Humble vs Official Tutorial Differences
- Official tutorial targets **Iron and newer** only. No `humble` branch exists in the repo.
- `followGpsWaypoints()` does NOT exist in Humble's `nav2_simple_commander`.
- **Workaround**: call `/fromLL` service (robot_localization) to convert lat/lon → map XY, then use standard `followWaypoints()` or `goToPose()`.
- `waitUntilNav2Active(localizer='controller_server')` — must pass `controller_server` not `robot_localization` to avoid lifecycle timeout on Humble.
- Source repo used: `Gutierrez-Cornejo-Emanuel/nav2_gps_waypoint_follower_demo` (Humble-adapted fork).

## Known Issues & Fixes Applied

### GAZEBO_MODEL_PATH must be exported before launch
The launch file sets it internally, but the shell must also have it exported. Add to `~/.bashrc`:
```bash
export GAZEBO_MODEL_PATH=/nav2gps_ws/install/nav2_gps_waypoint_follower_demo/share/nav2_gps_waypoint_follower_demo/models:/opt/ros/humble/share/turtlebot3_gazebo/models:$HOME/.gazebo/models
```

### sonoma_raceway model must be cached locally
Download to `~/.gazebo/models/sonoma_raceway/` before first launch. Gazebo hangs indefinitely trying to download it from `models.gazebosim.org`.

### navsat_transform IMU topic mismatch (fixed)
`model.sdf` publishes IMU on `/imu`, but `dual_ekf_navsat.launch.py` had a no-op remapping `("imu/data", "imu/data")`. Fixed to `("imu/data", "imu")`.

### Robot mesh renders grey (fixed)
Added explicit `Gazebo/DarkGrey` and `Gazebo/FlatBlack` material tags to visuals in `model.sdf`. The `.dae` mesh files cannot resolve their embedded textures in this setup.

### LiDAR scan hits floor at rear (fixed)
Robot tilts slightly on the banked Sonoma Raceway surface. Fixed by:
1. `min_range: 0.12` (was 0.0) — eliminates self-detection.
2. Scan angles changed from 360° to 240° (±120°) — removes rear sector where tilted scan hits the ground.

### logged_waypoint_follower did not wait for completion (fixed)
`followWaypoints()` is async. Added `isTaskComplete()` loop with feedback logging.

### interactive_waypoint_follower integrated into launch (fixed)
Added to `gps_waypoint_follower.launch.py` — starts automatically with `use_mapviz:=true`, no separate terminal needed.

## Mapviz Usage
- Config file: `config/gps_sky_demo.mvc` (OpenStreetMap tiles, no API key needed)
- **To send a GPS waypoint**: click directly on the map canvas — the `point_click_publisher` plugin publishes to `/clicked_point` in `wgs84` frame
- Robot position shown as green arrow (`tf_frame` on `base_link`)
- GPS track shown as blue dots (`navsat` on `/gps/fix`)
- Requires internet access inside Docker for tile downloads

## Mapviz `.mvc` Config Note
- `source: OpenStreetMap` — no API key required
- `output_frame: wgs84` on `point_click_publisher` — required for interactive follower to accept the click
- Fixed frame: `map` — matches EKF output frame
