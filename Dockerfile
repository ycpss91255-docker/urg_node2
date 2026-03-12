ARG ROS_DISTRO="humble"
ARG BUILD_TAG="base"
ARG RUNTIME_TAG="core"
ARG WS_PATH="/ros_ws"

############################## bats sources ##############################
FROM bats/bats:latest AS bats-src

FROM alpine:latest AS bats-extensions
RUN apk add --no-cache git && \
    git clone --depth 1 -b v0.3.0 \
        https://github.com/bats-core/bats-support /bats/bats-support && \
    git clone --depth 1 -b v2.1.0 \
        https://github.com/bats-core/bats-assert  /bats/bats-assert

############################## builder ##############################
FROM ros:${ROS_DISTRO}-ros-${BUILD_TAG}-jammy AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG WS_PATH
WORKDIR "${WS_PATH}"

# Pull source code
RUN git clone --recursive https://github.com/Hokuyo-aut/urg_node2.git \
        ./src/urg_node2

# Install dependencies and build
RUN apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN /ros_entrypoint.sh colcon build

############################## runtime ##############################
FROM ros:${ROS_DISTRO}-ros-${RUNTIME_TAG}-jammy AS runtime

ARG ROS_DISTRO

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        tini \
        ros-${ROS_DISTRO}-laser-proc \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy install from builder
ARG WS_PATH
COPY --from=builder "${WS_PATH}/install" "${WS_PATH}/install"

# Copy Hokuyo configuration
COPY --chmod=0644 config/ "${WS_PATH}/install/urg_node2/share/urg_node2/config"

COPY --chmod=0755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "urg_node2", "urg_node2.launch.py"]

############################## test (ephemeral) ##############################
FROM runtime AS test

COPY --from=bats-src /opt/bats /opt/bats
COPY --from=bats-src /usr/lib/bats /usr/lib/bats
COPY --from=bats-extensions /bats /usr/lib/bats
RUN ln -sf /opt/bats/bin/bats /usr/local/bin/bats

ENV BATS_LIB_PATH="/usr/lib/bats"

COPY smoke_test/ /smoke_test/

RUN bats /smoke_test/
