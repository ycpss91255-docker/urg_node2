# テストドキュメント

**21 件のテスト**。

## test/smoke/ros_env.bats

### ROS environment (3)

| テスト項目 | 説明 |
|------------|------|
| `ROS_DISTRO is set` | ROS_DISTRO environment variable is set |
| `ROS setup.bash exists` | `/opt/ros/${ROS_DISTRO}/setup.bash` exists |
| `ROS environment can be sourced` | ROS setup script sources without error |

### urg_node2 (4)

| テスト項目 | 説明 |
|------------|------|
| `urg_node2 workspace install exists` | `/ros_ws/install/urg_node2` directory exists |
| `urg_node2 local_setup.sh exists` | `/ros_ws/install/local_setup.sh` exists |
| `urg_node2 package is available` | `ros2 pkg list` includes urg_node2 |
| `urg_node2 config files exist` | `params_ether.yaml` and `params_serial.yaml` exist |

### System (1)

| テスト項目 | 説明 |
|------------|------|
| `entrypoint.sh exists and is executable` | `/entrypoint.sh` is executable |

### Dependencies (1)

| テスト項目 | 説明 |
|------------|------|
| `laser_proc package is available` | `ros2 pkg list` includes laser_proc |

## test/smoke/script_help.bats

### build.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `build.sh -h exits 0` | Help exits successfully |
| `build.sh --help exits 0` | Help exits successfully |
| `build.sh -h prints usage` | Help output contains "Usage:" |

### run.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `run.sh -h exits 0` | Help exits successfully |
| `run.sh --help exits 0` | Help exits successfully |
| `run.sh -h prints usage` | Help output contains "Usage:" |

### exec.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `exec.sh -h exits 0` | Help exits successfully |
| `exec.sh --help exits 0` | Help exits successfully |
| `exec.sh -h prints usage` | Help output contains "Usage:" |

### stop.sh (3)

| テスト項目 | 説明 |
|------------|------|
| `stop.sh -h exits 0` | Help exits successfully |
| `stop.sh --help exits 0` | Help exits successfully |
| `stop.sh -h prints usage` | Help output contains "Usage:" |
