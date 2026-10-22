---
estimated_duration: 30m
---

# Close A Resource Server That Allows Too Much

- **ID:** LAB
- **Slug:** ats-091-capstone-010
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `modelcapstone-demo`. Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-091-capstone-010
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-091-capstone-010`), not
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
