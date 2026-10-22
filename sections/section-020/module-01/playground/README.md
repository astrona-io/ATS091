# Write Policies That Decide Access — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-091-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, runs its preparation, and stays
running so you can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-091-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-091-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Preparation run once at startup |
| `manifests/` | Keycloak, the tester pod and any extra workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
