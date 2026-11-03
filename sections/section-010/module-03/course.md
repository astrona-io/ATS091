# Model Resources In Depth

A resource is the thing a permission protects, and most faults in a model are faults in how its resources are described. A resource without a type is missed by a permission written for that type. A permission without scopes covers more than the author meant. A resource with an owner follows different rules than a resource without one. This module takes the resource apart, one field and one rule at a time, and proves each rule with a decision request.

Keep one sentence in mind: **a permission finds a resource by its name or its type, and the fields of the resource decide what that permission covers.**

The module has four parts. **Describe A Resource** covers the fields a resource has and how to read and change them. **Types And Resource-Type Permissions** groups resources by type and protects the whole group with one permission; a graded lab follows it. **Resource Permissions And Scope Permissions** shows why a permission without scopes grants every scope. **Owners And Owner-Managed Access** explains the field `owner` and how it changes the decision.

## Learning objectives

After this module you can:

- Name the fields of a resource and read them with `kcadm.sh`.
- Give resources a type and protect all resources of that type with one permission.
- Say what a resource-based permission and a scope-based permission grant, and prove the difference with decisions.
- Explain the effect of `owner` and `ownerManagedAccess` on a decision.

## Before you start

You need the basics of Keycloak Authorization Services (resources, scopes, policies and permissions) and the `uma-ticket` decision request. Every command runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`resources-demo`**. User-managed access is switched on in the realm `inventory`, which holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` | The resource server, with the client secret `inventory-api-secret` (lab-only). It has the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
