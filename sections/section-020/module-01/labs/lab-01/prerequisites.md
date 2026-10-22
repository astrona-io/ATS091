# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Explain group policies, time policies and aggregated policies.
- Ask Keycloak for a decision with the `uma-ticket` grant.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`policies-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with the users `alice` (roles `inventory-viewer` and `inventory-manager`, group `staff`) and `bob` (role `inventory-viewer`), the public client `inventory-cli` and the confidential client `inventory-api`.
- The `tester` pod with `curl` and `jq`.


## Working rules

- Everything is graded on the **final state**: the decisions Keycloak makes at the end, and the objects that make them.
- Change one thing at a time and ask for a decision again. A second speculative change makes the first one unverifiable.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
