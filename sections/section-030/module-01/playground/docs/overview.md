# Overview: Enforce Decisions In An API With UMA 2.0 (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and the `inventory-api` service, creates the realm `inventory` with its authorization model, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`uma-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm **`inventory`** with `alice` (viewer and manager, password `alice-password`) and `bob` (viewer, password `bob-password`). User-Managed Access is **off**.
- The resource server **`inventory-api`** (client secret `inventory-api-secret`): the resource `items` with `view`, `edit` and `delete`, the permissions `view-items` (viewers), `edit-items` and `delete-items` (managers), in `ENFORCING` mode.
- The service **`inventory-api`** on port `3000`, a policy enforcement point: `GET`, `POST` and `DELETE` on `/items` need `view`, `edit` and `delete`. Its code is in the ConfigMap `inventory-api-code`, and its settings are environment variables of the Deployment.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `call_api` sends a request to `inventory-api` as a user and prints the status code. `pat` gets a protection API token for `inventory-api`. The token request in `user_token` uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=uma-demo
KEYCLOAK=http://keycloak:8080/realms/inventory
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
in_tester() { kubectl -n "$NAMESPACE" exec deploy/tester -- "$@"; }
user_token() {
  in_tester sh -c "curl -s $KEYCLOAK/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=$1 -d password=$1-password | jq -r .access_token"
}
pat() {
  in_tester sh -c "curl -s $KEYCLOAK/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-api \
    -d client_secret=inventory-api-secret | jq -r .access_token"
}
call_api() {
  in_tester curl -s -o /dev/null -w '%{http_code}\n' \
    -X "$2" -H "Authorization: Bearer $(user_token "$1")" http://inventory-api:3000/items
}
```

Use them like this: `call_api bob DELETE`, `PAT=$(pat)`.

## Practice tasks

- Send `GET`, `POST` and `DELETE` as `alice` and `bob`, then read `kubectl -n uma-demo logs deploy/inventory-api` and match each line to a request.
- Create a permission ticket for `items#edit` with a PAT, and exchange it for an RPT as each user.
- Switch on User-Managed Access, create a resource owned by `alice`, and share it with `bob` through the Protection API or the Account Console.
- Set `KEYCLOAK_AUDIENCE` of the Deployment to a wrong value with `kubectl -n uma-demo set env deployment/inventory-api KEYCLOAK_AUDIENCE=wrong`, and see what the API and its log do. Set it back to `inventory-api`.
- Make `delete-items` use `inventory-viewers` and predict `call_api bob DELETE` before you run it.
