# Protect An API With Keycloak Authorization Services

The inventory API has three actions on its items: view them, edit them and delete them. Everyone with the role `inventory-viewer` may view. Only people with the role `inventory-manager` may edit or delete. The API could check those roles in its own code, and many APIs do. This module shows a different way: the API asks Keycloak, and Keycloak decides.

Keycloak Authorization Services is the part of Keycloak that stores what an API protects and the rules that protect it. A client with authorization switched on is a **resource server**. It owns **resources** (the things to protect), **scopes** (the actions on them), **policies** (rules that grant or deny) and **permissions** (which policies protect which resources or scopes).

Keep one sentence in mind: **a policy decides, a permission protects.** A policy on its own protects nothing. Only a permission joins a policy to a resource or a scope.

The module has three parts. **Why Roles In A Token Are Not Enough** compares role-based and policy-based access control and switches authorization on for `inventory-api`. **Resources, Scopes And Permissions** builds the model step by step and asks Keycloak for the first decisions. A graded lab follows it. **Decision Strategies And The Enforcement Mode** shows what happens when several policies disagree, and when no permission matches at all.

## Learning objectives

After this module you can:

- Explain what a role-based check in an API cannot express, and what Authorization Services adds.
- Switch on authorization for a confidential client with `kcadm.sh`.
- Create scopes, a resource with URIs and a role policy.
- Protect each scope with a scope permission.
- Ask Keycloak for a decision with the `uma-ticket` grant and read the answer.
- Choose a decision strategy and predict its result for a set of policy results.
- Explain the three policy enforcement modes and why `ENFORCING` is the only safe default.

## Before you start

You need Kubernetes basics (namespaces, pods, `kubectl exec`) and `curl`. You also need the basics of Keycloak: a realm holds users and clients, and a client can request tokens from the token endpoint. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`model-demo`**. It holds:

| Name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| user `bob` | Role `inventory-viewer` only, password `bob-password` |
| client `inventory-cli` | A public client with direct access grants; you use it to get tokens for `alice` and `bob` |
| client `inventory-api` | A confidential client with a service account; it becomes the resource server |
| pod `tester` | A client with `curl` and `jq`; every token and decision request is sent from here |

The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
