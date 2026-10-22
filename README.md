# ATS091 — Fine-Grained Authorization Services (Keycloak)

Course material for the **Fine-Grained Authorization Services** domain of the
Astrona Keycloak training path ([ATP018](https://github.com/astrona-io/ATP018)),
which is **15% of the path**. Written for **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation. None has been started on a cluster,
> and no lab has passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | The Authorization Services Model | 1 | 1 + capstone | Resource servers, resources, scopes, permissions |
| [020](sections/section-020) | Policies And Decisions | 1 | 1 + capstone | Policy types and decision requests |
| [030](sections/section-030) | UMA 2.0 And Policy Enforcement | 1 | 1 + capstone | UMA, the RPT and an enforcing API |

The order goes from the model to the code. Section 010 builds the model a
resource server needs. Section 020 fills it with richer rules than roles.
Section 030 follows the decision into an API that enforces it, through UMA 2.0.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Protect An API With Keycloak Authorization Services](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Write Policies That Decide Access](sections/section-020/module-01/course.md) | 4 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Enforce Decisions In An API With UMA 2.0](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Close A Resource Server That Allows Too Much | `PERMISSIVE` mode, an `AFFIRMATIVE` permission with a viewer policy, a missing permission |
| [020](sections/section-020/capstone/labs/lab-01) | Fix A Policy Set That Decides For The Wrong Users | a regex for the wrong domain, a negative group policy, an `AFFIRMATIVE` aggregate |
| [030](sections/section-030/capstone/labs/lab-01) | Make The Inventory API Enforce Its Rules | a wrong audience in the API, a resource without the `edit` scope, a view permission on the wrong policy |

---

## The lab environment

Every playground and lab is a **kind** cluster with Keycloak 26.8.1 deployed
from plain Kubernetes manifests, the realm `inventory` (users `alice` and
`bob`, clients `inventory-cli` and `inventory-api`), and a `tester` pod.
Section 030 adds `inventory-api`, a small Node.js policy enforcement point
(`node:22-alpine`, code in a ConfigMap). Bootstrap, solution and grader scripts
share one set of shell helpers (`kcadm`, `authz_id`, `user_token`, `decision`)
copied into each script, so each script runs on its own.

JavaScript policies are taught in prose only: deploying one needs a JAR built
into the server and the preview feature `scripts`, which a lab cannot do.
Graders never grade a decision that a time policy can flip.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (switching to
`PERMISSIVE`, deleting and recreating a permission, removing a role from a
user, changing the API's code).
