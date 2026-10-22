# Write Policies That Decide Access

The inventory API already has a working model: viewers view, managers edit and delete. Then the security team adds a rule. Deleting items is allowed only for members of the group `staff`, and only during business hours. No single role can express that rule. This module shows the policy types that can, and how to combine them into one decision.

A **policy** in Keycloak Authorization Services is a rule that grants or denies on its own. Each policy type reads a different input: the user's roles, the user's identity, the user's groups, the client that asks, a claim in the token, or the clock. A **permission** then uses one or more policies to protect a resource or a scope.

Keep one sentence in mind: **each policy type answers one question, and an aggregated policy asks several questions at once.**

The module has four parts. **Role, User, Group, Client And Regex Policies** covers the policies that look at who is asking, plus positive and negative logic. **Time Policies And Aggregated Policies** adds the clock and combines policies into one; a graded lab follows it. **JavaScript Policies** explains the one policy type that you deploy as a file on the server. **Asking Keycloak For A Decision** looks closely at the request an API sends and the three kinds of answer it can get.

## Learning objectives

After this module you can:

- Choose the right policy type for a rule, and create it with `kcadm.sh`.
- Explain positive and negative logic, and predict a negative policy's result.
- Create a time policy and explain why its result depends on the server's clock.
- Combine policies in an aggregated policy and pick its decision strategy.
- Explain how a JavaScript policy is deployed and why it cannot be uploaded.
- Ask Keycloak for a decision, for a list of permissions, and for a requesting party token, and read each answer.

## Before you start

You need Kubernetes basics (`kubectl exec`) and `curl`. You also need the basics of Keycloak Authorization Services: a client with authorization switched on is a resource server; it holds scopes, resources, policies and permissions; and an API asks Keycloak for a decision with the `uma-ticket` grant. Every command in the parts runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`policies-demo`**. The realm `inventory` holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, member of the group `staff`, email `alice@example.com` |
| `bob` | Role `inventory-viewer`, in no group, email `bob@example.com` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` | The resource server: the resource `items` with the scopes `view`, `edit` and `delete`, the role policies `inventory-viewers` and `inventory-managers`, and the scope permissions `view-items`, `edit-items` and `delete-items` |
| `tester` | A pod with `curl` and `jq`; every token and decision request is sent from here |

The passwords are `alice-password` and `bob-password`. The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
