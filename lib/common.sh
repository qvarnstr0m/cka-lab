#!/usr/bin/env bash
# Shared helpers for host, vm, cluster and exercise scripts.
# Source it:  source "$(dirname "$0")/../lib/common.sh"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# shellcheck source=../config/versions.env
source "${REPO_ROOT}/config/versions.env"
# shellcheck source=../config/cluster.env
source "${REPO_ROOT}/config/cluster.env"

# Lab-local known_hosts so recreated VMs don't trip host key checks in ~/.ssh
LAB_KNOWN_HOSTS="${REPO_ROOT}/.lab/known_hosts"
mkdir -p "$(dirname "${LAB_KNOWN_HOSTS}")"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# node_ip <name>
node_ip() {
  local i
  for i in "${!NODES[@]}"; do
    if [[ "${NODES[$i]}" == "$1" ]]; then
      echo "${NODE_IPS[$i]}"
      return 0
    fi
  done
  die "unknown node: $1"
}

control_plane() { echo "${NODES[0]}"; }
workers()       { echo "${NODES[@]:1}"; }

SSH_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="${LAB_KNOWN_HOSTS}"
  -o ConnectTimeout=5
  -o LogLevel=ERROR
  -i "${SSH_PRIVKEY_FILE}"
)

# node_ssh <name> [command...]   run a command on a node
node_ssh() {
  local node="$1"; shift
  # shellcheck disable=SC2029 # remote expansion is intended
  ssh "${SSH_OPTS[@]}" "${VM_USER}@$(node_ip "${node}")" "$@"
}

# node_run_script <name> <script> [VAR=value...]
# Run a local script on a node as root, passing environment variables.
node_run_script() {
  local node="$1" script="$2"; shift 2
  node_ssh "${node}" sudo env "$@" bash -s < "${script}"
}

# wait_for_ssh <name> [timeout-seconds]
wait_for_ssh() {
  local node="$1" timeout="${2:-300}" start
  start=$(date +%s)
  until node_ssh "${node}" true 2>/dev/null; do
    (( $(date +%s) - start > timeout )) && die "timed out waiting for SSH on ${node}"
    sleep 5
  done
}

# kubectl on the control plane, from the host
cp_kubectl() {
  node_ssh "$(control_plane)" kubectl "$@"
}
