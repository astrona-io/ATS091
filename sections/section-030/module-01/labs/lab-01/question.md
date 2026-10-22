# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** policy enforcement

## Scenario

`inventory-api` in the namespace `uma-demo` asks Keycloak for a decision on every request. A support ticket says that `bob`, who should only read items, deleted several of them this morning:

```sh
kubectl -n uma-demo exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' -X DELETE \
  -H "Authorization: Bearer <a token for bob>" http://inventory-api:3000/items
```

The access rules are:

| Request | Allowed for |
| --- | --- |
| `GET /items` | users with the realm role `inventory-viewer` |
| `POST /items` | users with the realm role `inventory-manager` |
| `DELETE /items` | users with the realm role `inventory-manager` |

## Your task

Find out whether the API or the authorization model in Keycloak is at fault, and fix it so that `inventory-api` follows the table. Get tokens with the public client `inventory-cli` and the password grant (`alice-password`, `bob-password`); this is only for testing.

## Constraints

- **Do not change `inventory-api`**: not its code (the ConfigMap `inventory-api-code`) and not its settings.
- Do not change users or their roles.
- Keep the policy enforcement mode `ENFORCING`.

## Done when

- `alice` gets `200` for `GET`, `POST` and `DELETE` on `/items`.
- `bob` gets `200` for `GET` and `403` for `POST` and `DELETE`.
- A request without a token gets `401`.
- `delete-items` uses only the policy `inventory-managers`.
