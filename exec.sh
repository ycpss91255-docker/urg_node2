#!/usr/bin/env bash

set -euo pipefail

CONTAINER="urg_node2"
CMD="${1:-bash}"

docker exec -it "${CONTAINER}" "${CMD}"
