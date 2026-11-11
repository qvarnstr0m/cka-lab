SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

NAME ?=
E ?=
JUMP ?= lab-host

EXERCISE_DIR = exercises/$(E)

.PHONY: help
help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

## --- Host ---------------------------------------------------------------

.PHONY: host check network
host: ## Install KVM/libvirt and create the lab network (once, on the host)
	./host/install.sh
	sg libvirt -c ./host/network.sh

check: ## Check KVM, libvirt, memory and disk
	./host/check.sh

network: ## (Re)create the libvirt network with DHCP reservations
	./host/network.sh

## --- VMs ----------------------------------------------------------------

.PHONY: vms destroy ssh-config
vms: ## Create the cluster VMs (cp, worker1, worker2)
	./vm/create.sh

destroy: ## Destroy all VMs, snapshots and disks
	./vm/destroy.sh

ssh-config: ## Print an ~/.ssh/config block for your own computer (JUMP=lab-host)
	@./vm/ssh-config.sh $(JUMP)

## --- Cluster ------------------------------------------------------------

.PHONY: cluster cluster-prev reset
cluster: ## Build the cluster with kubeadm + Calico
	./cluster/up.sh

cluster-prev: ## Build the cluster one minor version behind (for the upgrade exercise)
	source config/versions.env && K8S_MINOR=$$K8S_MINOR_PREV ./cluster/up.sh

reset: ## kubeadm reset on all nodes
	./cluster/reset.sh

## --- Snapshots ----------------------------------------------------------

.PHONY: snapshot restore snapshots
snapshot: ## Snapshot all nodes (NAME=clean)
	@test -n "$(NAME)" || { echo "usage: make snapshot NAME=<name>"; exit 1; }
	./vm/snapshot.sh save $(NAME)

restore: ## Restore all nodes to a snapshot (NAME=clean)
	@test -n "$(NAME)" || { echo "usage: make restore NAME=<name>"; exit 1; }
	./vm/snapshot.sh restore $(NAME)

snapshots: ## List snapshots
	./vm/snapshot.sh list

## --- Exercises ----------------------------------------------------------

.PHONY: exercises exercise verify solution
exercises: ## List exercises
	@find exercises -name task.md -not -path '*/lib/*' | sed 's#exercises/##; s#/task.md##' | sort

exercise: ## Set up an exercise and show the task (E=troubleshooting/broken-kubelet)
	@test -d "$(EXERCISE_DIR)" || { echo "unknown exercise: $(E) (make exercises)"; exit 1; }
	./$(EXERCISE_DIR)/setup.sh
	@echo; cat $(EXERCISE_DIR)/task.md

verify: ## Check your solution (E=...)
	@test -d "$(EXERCISE_DIR)" || { echo "unknown exercise: $(E)"; exit 1; }
	./$(EXERCISE_DIR)/verify.sh

solution: ## Show the solution (E=...)
	@cat $(EXERCISE_DIR)/solution.md

## --- Repo ---------------------------------------------------------------

.PHONY: lint
lint: ## Run shellcheck, yamllint and markdownlint locally
	shellcheck $$(git ls-files '*.sh')
	yamllint .
	npx --yes markdownlint-cli2 '**/*.md'
