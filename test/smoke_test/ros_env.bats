#!/usr/bin/env bats

setup() {
    load "${BATS_TEST_DIRNAME}/test_helper"
}

# -------------------- ROS environment --------------------

@test "ROS_DISTRO is set" {
    assert [ -n "${ROS_DISTRO}" ]
}

@test "ROS setup.bash exists" {
    assert [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]
}

@test "ROS environment can be sourced" {
    run bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && echo ok"
    assert_success
    assert_output "ok"
}

# -------------------- urg_node2 --------------------

@test "urg_node2 workspace install exists" {
    assert [ -d "/ros_ws/install/urg_node2" ]
}

@test "urg_node2 local_setup.sh exists" {
    assert [ -f "/ros_ws/install/local_setup.sh" ]
}

@test "urg_node2 package is available" {
    run bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && source /ros_ws/install/local_setup.sh && ros2 pkg list | grep urg_node2"
    assert_success
}

@test "urg_node2 config files exist" {
    assert [ -f "/ros_ws/install/urg_node2/share/urg_node2/config/params_ether.yaml" ]
    assert [ -f "/ros_ws/install/urg_node2/share/urg_node2/config/params_serial.yaml" ]
}

# -------------------- System --------------------

@test "entrypoint.sh exists and is executable" {
    assert [ -x "/entrypoint.sh" ]
}

@test "laser_proc package is available" {
    run bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && ros2 pkg list | grep laser_proc"
    assert_success
}
