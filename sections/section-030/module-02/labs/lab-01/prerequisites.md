# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Get a protection API token with the client credentials grant.
- Explain resources, scopes and permission tickets.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`protection-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with user-managed access on, the users `alice` and `bob` and the public client `inventory-cli`.
- The resource server `inventory-api` with the client secret `inventory-api-secret` (lab-only) and the resource `alice-shelf` shared with `bob` for `view` and `edit`.
- The `tester` pod with `curl` and `jq`.

## Working rules

- Everything is graded on the **final state**: decisions for `alice` and `bob`, and the tickets on `alice-shelf`.
- Get user tokens with the password grant of `inventory-cli` only to test. A real application uses the authorization code flow.
