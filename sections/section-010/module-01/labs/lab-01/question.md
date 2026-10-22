# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** the authorization model

## Scenario

The team behind `inventory-api` wants Keycloak to decide who may do what, instead of checking roles in the API's code. The client `inventory-api` in the realm `inventory` of the namespace `model-demo` exists, but authorization is switched off and no model exists yet.

The access rules are:

| Action on items | Allowed for |
| --- | --- |
| view | users with the realm role `inventory-viewer` |
| edit | users with the realm role `inventory-manager` |
| delete | users with the realm role `inventory-manager` |

## Your task

1. Switch on authorization for the client `inventory-api`.
2. Create the scopes `view`, `edit` and `delete`, and a resource named `items` with the URIs `/items` and `/items/*` that lists all three scopes.
3. Create a role policy `inventory-viewers` for the role `inventory-viewer`, and a role policy `inventory-managers` for the role `inventory-manager`.
4. Create three scope permissions, `view-items`, `edit-items` and `delete-items`, that protect each scope of `items` according to the table.

## Constraints

- Use role policies. Do not write a policy that names `alice` or `bob` directly.
- Keep the policy enforcement mode `ENFORCING`.
- Do not change the users, their roles or the client `inventory-cli`.

## Done when

- `alice` is granted `items#view`, `items#edit` and `items#delete` by a decision request with `audience=inventory-api`.
- `bob` is granted `items#view` and denied `items#edit` and `items#delete`.
- The three permissions exist and use role policies only.
