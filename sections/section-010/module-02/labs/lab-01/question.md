# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** authorization-model

## Scenario

`inventory-api` in the namespace `settings-demo` has a finished authorization model. The team starts a second copy of the service and registers it as the client `inventory-api-v2`. Its resource server is switched on and has no model of its own. The team wants the same rules on the second server and does not want to build them again by hand.

## Your task

1. Export the authorization settings of `inventory-api`.
2. Load them into `inventory-api-v2`, so it has the same resource, scopes, policies and permissions.
3. Prove that `inventory-api-v2` decides like `inventory-api` for `alice` and `bob`.

## Constraints

- Do not change `inventory-api`, the users, the roles or the realm.
- Keep the policy enforcement mode `ENFORCING` on both resource servers.
- Do not create the objects of `inventory-api-v2` one by one.

## Done when

- `inventory-api-v2` has the resource `items`, the scopes `view`, `edit` and `delete`, the policies `inventory-viewers` and `inventory-managers` and the permissions `view-items`, `edit-items` and `delete-items`.
- With `audience=inventory-api-v2`, `alice` is granted `view`, `edit` and `delete`, and `bob` is granted `view` and denied `edit` and `delete`.
- `inventory-api` still decides as before.
