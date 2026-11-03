# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Read a resource and its permissions through the Admin REST API.
- Ask Keycloak for a decision with the `uma-ticket` grant.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`resources-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with the users `alice` and `bob` and the public client `inventory-cli`.
- The resource server `inventory-api` with the resources `shelf-a`, `shelf-b`, `shelf-c` and `vault`, and the permission `view-shelves`.
- The `tester` pod with `curl` and `jq`.

## Working rules

- Everything is graded on the **final state**: decisions for `bob`, the type of `shelf-c` and the list of permissions.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
