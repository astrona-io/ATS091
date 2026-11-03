# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Explain resources, scopes, policies and permissions.
- Ask Keycloak for a decision with the `uma-ticket` grant and an `audience`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`settings-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with the users `alice` (roles `inventory-viewer` and `inventory-manager`) and `bob` (role `inventory-viewer`), the public client `inventory-cli` and the confidential clients `inventory-api` and `inventory-api-v2`.
- The finished model on `inventory-api`, and authorization switched on for `inventory-api-v2` with no model of its own.
- The `tester` pod with `curl` and `jq`.

## Working rules

- Everything is graded on the **final state**: the objects of `inventory-api-v2` and the decisions both servers make.
- Look at what `inventory-api-v2` holds before you import anything.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
