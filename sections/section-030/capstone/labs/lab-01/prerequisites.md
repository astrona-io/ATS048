# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `python3` on the machine that runs the lab.
- You finished the two modules of this section or know retention flags and the sample_limit setting.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Prometheus, the example `probe` application and a traffic generator in the `starfleet` namespace. `kubectl` already points at that cluster as the cluster administrator.
