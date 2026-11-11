#!/usr/bin/env bash
# Helpers for exercise setup.sh / verify.sh scripts.
# Source it:  source "$(dirname "$0")/../../lib/exercise.sh"

# shellcheck source=../../lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/lib/common.sh"

_checks_failed=0

# check "<description>" <command...>   records pass/fail, never exits
check() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then
    printf '  \033[32mPASS\033[0m %s\n' "${desc}"
  else
    printf '  \033[31mFAIL\033[0m %s\n' "${desc}"
    _checks_failed=1
  fi
}

# finish   print the result and exit with the right status (end of verify.sh)
finish() {
  echo
  if (( _checks_failed )); then
    echo "Not solved yet."
    exit 1
  fi
  echo "Solved."
}

# node_ready <node>
node_ready() {
  [[ "$(cp_kubectl get node "$1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" == "True" ]]
}

# wait_for_pod <namespace> <selector> [timeout]
wait_for_pod() {
  cp_kubectl wait -n "$1" --for=condition=Ready pod -l "$2" --timeout="${3:-120s}"
}

# require_cluster   abort setup if the cluster isn't reachable
require_cluster() {
  cp_kubectl get nodes &>/dev/null || die "cluster not reachable (make cluster / make restore NAME=clean)"
}
