---
estimated_duration: 25m
---

# Allow Only One Client To Export

- **ID:** LAB
- **Slug:** ats-091-lab-020-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `clients-demo`. Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-091-lab-020-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-091-lab-020-03`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Keycloak, the realm, and the starting state |
| `manifests/` | Workloads applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Keycloak before the reference solution runs |
| `validation/` | Grading scripts, one per check |
