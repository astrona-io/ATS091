# Debug Decisions With The Evaluation Tool

A decision request tells you that Keycloak answered `403`. It does not tell you why. When a permission has several policies, and one policy is an aggregated policy of other policies, the reason hides three levels down. Keycloak has a tool for this problem: the evaluation tool. It runs the same evaluation as a real request, for any user, and returns the result of every policy on the way. This module teaches you to ask that question, read the answer and use it to find a fault.

The tool is part of the policy administration point, so it needs administrator access and it does not need a token of the user. That is why it can answer "what would happen if" questions, which a real decision request cannot.

Keep one sentence in mind: **a decision request tells you the result, the evaluation tool tells you which policy produced it.**

The module has four parts. **Ask The Evaluation Tool For A Result** sends the first evaluation request and reads the result of one permission. **Find The Policy That Denies** follows a denial down the permission, the policy and the policies inside an aggregated policy; a graded lab follows it. **Ask What-If Questions** evaluates for another user, other roles and other context attributes without changing anything. **Evaluate All Permissions Of A User** asks for every permission a user holds and compares the answer with a real decision request.

## Learning objectives

After this module you can:

- Send an evaluation request to the Admin REST API and name the fields of the answer.
- Say which permission and which policy produced a `DENY`.
- Evaluate for a different user, a different set of roles or different context attributes without changing the realm.
- List every permission of a user and compare the evaluation with a real decision request.

## Before you start

You need the basics of Keycloak Authorization Services (resources, scopes, policies and permissions) and the `uma-ticket` decision request. Every command runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`evaluate-demo`**. The realm `inventory` holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, member of the group `staff`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `dana` | Roles `inventory-viewer` and `inventory-manager`, no group, password `dana-password` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` | The resource server: the resource `items` with the scopes `view`, `edit` and `delete`. The permission `delete-items` uses the aggregated policy `staff-managers`, which holds the role policy `inventory-managers` and the group policy `staff-only` |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
