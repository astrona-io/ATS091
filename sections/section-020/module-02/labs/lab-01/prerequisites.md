# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Explain role policies, group policies and aggregated policies, and the strategy `UNANIMOUS`.
- Send a request to the evaluation tool and read the status of each policy in the answer.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`evaluate-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with `alice` (managers role, in the group `staff`), `bob` (viewer) and `dana` (viewer and manager, no group), and the public client `inventory-cli`.
- The resource server `inventory-api` with the resource `items`, three scope permissions, and an aggregated policy on the delete permission.
- The `tester` pod with `curl` and `jq`.

## Working rules

- Everything is graded on the **final state**: the decisions for `alice`, `bob` and `dana`, and that the model is unchanged.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
