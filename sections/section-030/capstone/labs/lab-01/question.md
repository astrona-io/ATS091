# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** policy enforcement

## Scenario

`inventory-api` in the namespace `umacapstone-demo` should follow these rules, but after a rushed release it answers almost every request wrongly:

| Request | Allowed for |
| --- | --- |
| `GET /items` | users with the realm role `inventory-viewer` |
| `POST /items` | users with the realm role `inventory-manager` |
| `DELETE /items` | users with the realm role `inventory-manager` |

`alice` holds both roles; `bob` holds only `inventory-viewer`. Get tokens with the public client `inventory-cli` and the password grant (`alice-password`, `bob-password`); this is only for testing.

## Your task

Find every fault between `inventory-api` and its resource server in Keycloak and fix it. Some faults may be in the API's settings and some in the authorization model; they are independent. Use the API's log and direct decision requests to Keycloak to tell them apart.

## Constraints

- **Do not change the API's code** (the ConfigMap `inventory-api-code`). You may change the Deployment's environment variables.
- Do not change users or their roles.
- Keep the policy enforcement mode `ENFORCING`.

## Done when

- `alice` gets `200` for `GET`, `POST` and `DELETE` on `/items`; `bob` gets `200` for `GET` and `403` for `POST` and `DELETE`; a request without a token gets `401`.
- `inventory-api` asks for the audience `inventory-api`.
- The resource `items` lists `view`, `edit` and `delete`, and `view-items` uses only `inventory-viewers`.
