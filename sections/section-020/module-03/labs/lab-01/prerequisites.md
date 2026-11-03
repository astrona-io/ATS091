# Prerequisites

Before starting this lab you should be able to:

- Run `kcadm.sh` commands inside a pod with `kubectl exec`.
- Create a policy and a scope permission with the Admin REST API.
- Ask Keycloak for a decision with the `uma-ticket` grant.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`clients-demo`**, with the administrator `admin` and the password `admin` in the `master` realm. These are lab-only credentials.
- The realm `inventory` with the users `alice` and `bob` and the public clients `inventory-cli` and `billing-cli`, both with Direct access grants.
- The resource server `inventory-api` with the original model and the resource `invoices`.
- The `tester` pod with `curl` and `jq`.

## Working rules

- Everything is graded on the **final state**: decisions from both clients and the policies in the resource server.
- Get user tokens with the password grant only to test. A real application uses the authorization code flow.
