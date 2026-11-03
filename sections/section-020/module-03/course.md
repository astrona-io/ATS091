# Decide By Client And Client Scope

Most policies ask who the user is: which role, which group, which user. Some rules ask which application is making the request. A back office tool may export reports, while a public mobile app, used by the same person, must not. Keycloak has two policy types for this: the client policy and the client scope policy. This module builds both and proves each one with decision requests from two different clients.

Keep one sentence in mind: **a user policy checks the person, a client policy checks the application the person used, and a client scope policy checks what the application was allowed to ask for.**

The module has two parts. **Client Policies** grants a permission only to requests from chosen clients; a graded lab follows it. **Client Scope Policies** grants a permission only when the token carries a chosen client scope.

## Learning objectives

After this module you can:

- Create a client policy and attach it to a scope permission.
- Prove that the same user is granted from one client and denied from another.
- Create a client scope policy and explain what it reads from the token.
- Choose between a role policy, a client policy and a client scope policy for a rule.

## Before you start

You need the basics of Keycloak Authorization Services (resources, scopes, policies and permissions) and the `uma-ticket` decision request. Every command runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`clients-demo`**. The realm `inventory` holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `inventory-cli` | Public client with Direct access grants; you use it to get tokens for `alice` and `bob` |
| `reports-cli` | A second public client with Direct access grants, to show that the client changes the decision |
| `inventory-write` | A client scope, assigned to `inventory-cli` as an optional scope |
| `inventory-api` | The resource server, with the client secret `inventory-api-secret` (lab-only). It has the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
