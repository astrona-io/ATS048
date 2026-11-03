# Explore Labels And Cardinality - Playground

- **Slug:** ats-048-playground-040-02
- **Type:** Astrona playground, a clean environment with no task and no grading
- **Status:** UNTESTED. Written and statically checked, never booted.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Prometheus v3.5.5 and the example `probe` application. Nothing to submit.

## Run it

```sh
astrona run -c sections/section-040/module-02/playground
astrona destroy ats-048-playground-040-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/` | Starting objects |
| `docs/overview.md` | The guided exercise |
