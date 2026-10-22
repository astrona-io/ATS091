# Prerequisites

Before starting this lab you should be able to:

- Send HTTP requests with `curl` from a pod with `kubectl exec`.
- Read a scope permission and its policies with `kcadm.sh`.
- Explain what a policy enforcement point does.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`uma-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with the users `alice` (roles `inventory-viewer` and `inventory-manager`, group `staff`) and `bob` (role `inventory-viewer`), the public client `inventory-cli` and the confidential client `inventory-api`.
- The `tester` pod with `curl` and `jq`.
- The API `inventory-api` on port `3000`, which asks Keycloak for a decision on every request.

## Working rules

- Everything is graded on the **final state**: the decisions Keycloak makes at the end, and the objects that make them.
- Change one thing at a time and ask for a decision again. A second speculative change makes the first one unverifiable.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
