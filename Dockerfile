ARG ROS_DISTRO="humble"
ARG BUILD_TAG="base"
ARG RUNTIME_TAG="core"
ARG WS_PATH="/ros_ws"

############################## test tool sources ##############################
FROM bats/bats:latest AS bats-src

FROM alpine:latest AS bats-extensions
RUN apk add --no-cache git && \
    git clone --depth 1 -b v0.3.0 \
        https://github.com/bats-core/bats-support /bats/bats-support && \
    git clone --depth 1 -b v2.1.0 \
        https://github.com/bats-core/bats-assert  /bats/bats-assert

FROM alpine:latest AS lint-tools
RUN apk add --no-cache curl xz && \
    curl -fsSL \
        https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz \
        | tar -xJ -C /tmp && \
    mv /tmp/shellcheck-v0.10.0/shellcheck /usr/local/bin/shellcheck && \
    curl -fsSL -o /usr/local/bin/hadolint \
        https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 && \
    chmod +x /usr/local/bin/hadolint

############################## builder ##############################
FROM ros:${ROS_DISTRO}-ros-${BUILD_TAG}-jammy AS builder

ARG APT_MIRROR_UBUNTU="tw.archive.ubuntu.com"
RUN sed -i "s@archive.ubuntu.com@${APT_MIRROR_UBUNTU}@g" /etc/apt/sources.list || true && \
    apt-get update && \
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

############################## devel ##############################
FROM ros:${ROS_DISTRO}-ros-${RUNTIME_TAG}-jammy AS devel

ARG ROS_DISTRO
ARG APT_MIRROR_UBUNTU="tw.archive.ubuntu.com"

RUN sed -i "s@archive.ubuntu.com@${APT_MIRROR_UBUNTU}@g" /etc/apt/sources.list || true && \
    apt-get update && \
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

COPY --chmod=0755 script/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "urg_node2", "urg_node2.launch.py"]

############################## test (ephemeral) ##############################
FROM devel AS test

# Install lint tools
COPY --from=lint-tools /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=lint-tools /usr/local/bin/hadolint /usr/local/bin/hadolint

# Lint: ShellCheck (.sh) + Hadolint (Dockerfile)
COPY .hadolint.yaml /lint/.hadolint.yaml
COPY Dockerfile /lint/Dockerfile
COPY template/script/docker/build.sh template/script/docker/run.sh template/script/docker/exec.sh template/script/docker/stop.sh /lint/
COPY script/entrypoint.sh /lint/
RUN shellcheck -S warning /lint/*.sh
RUN cd /lint && hadolint Dockerfile

# Install bats
COPY --from=bats-src /opt/bats /opt/bats
COPY --from=bats-src /usr/lib/bats /usr/lib/bats
COPY --from=bats-extensions /bats /usr/lib/bats
RUN ln -sf /opt/bats/bin/bats /usr/local/bin/bats

ENV BATS_LIB_PATH="/usr/lib/bats"

# Smoke test
COPY template/test/smoke/test_helper.bash template/test/smoke/script_help.bats /smoke_test/
COPY test/smoke/ /smoke_test/

RUN bats /smoke_test/
