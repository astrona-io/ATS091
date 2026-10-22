# Enforce Decisions In An API With UMA 2.0

Keycloak can now decide that `bob` may view items but not delete them. The inventory API still has to act on that decision. If it never asks, or asks the wrong question, `bob` deletes items anyway. This module follows the decision all the way into the API, through the standard Keycloak builds on: User-Managed Access (UMA) 2.0.

UMA 2.0 is an extension of OAuth 2.0. In it, a resource server that refuses a request hands out a **permission ticket**, and the client exchanges that ticket at Keycloak for a **requesting party token (RPT)**, an access token that carries the granted permissions. UMA also lets users own resources and share them with other users. An API that asks Keycloak and enforces the answer is a **policy enforcement point (PEP)**.

Keep one sentence in mind: **Keycloak decides, the policy enforcement point enforces, and either one can be wrong.**

The module has three parts. **UMA 2.0, Permission Tickets And The RPT** walks through the UMA flow by hand, with the Protection API and a protection API token. **User-Managed Access And Sharing** lets `alice` own a resource and share it with `bob`. **A Policy Enforcement Point In An API** reads the code of `inventory-api`, sends it requests as each user, and traces its answers back to Keycloak; a graded lab follows it.

## Learning objectives

After this module you can:

- Describe the UMA 2.0 flow from the first `401` to the RPT.
- Get a protection API token for a resource server and create a permission ticket with it.
- Exchange a permission ticket for an RPT and read its `authorization` claim.
- Switch on User-Managed Access for a realm and share a user-owned resource.
- Explain how a policy enforcement point maps a request to a resource and a scope.
- Trace a wrong API answer to the API's settings or to the authorization model, and fix the right one.

## Before you start

You need Kubernetes basics (`kubectl exec`, `kubectl logs`, `kubectl get`), `curl` and `jq`. You also need the basics of Keycloak Authorization Services: a resource server holds resources, scopes, policies and permissions, and the `uma-ticket` grant asks Keycloak for a decision. Every command in the parts runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`uma-demo`**:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` (client) | The resource server, with client secret `inventory-api-secret`: the resource `items` with the scopes `view`, `edit` and `delete`, and the permissions `view-items` (viewers), `edit-items` and `delete-items` (managers) |
| `inventory-api` (Deployment and Service) | The API itself, on port `3000`, a policy enforcement point |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. All these credentials are lab-only.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
