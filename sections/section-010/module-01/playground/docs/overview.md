# Overview: Protect An API With Keycloak Authorization Services (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory` with its users and clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`model-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm **`inventory`**:

  | Name | What it is |
  | --- | --- |
  | `alice` | Realm roles `inventory-viewer` and `inventory-manager`, group `staff`, password `alice-password` |
  | `bob` | Realm role `inventory-viewer`, password `bob-password` |
  | `inventory-cli` | Public client with direct access grants, for getting user tokens from a terminal |
  | `inventory-api` | Confidential client with a service account; authorization is **not** switched on yet |

- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration tool inside the Keycloak pod. `authz_id` looks up the id of a scope, resource or policy of `inventory-api` by name; it works once authorization is switched on. `decision` asks Keycloak whether a user may use a scope and prints `200` (granted) or `403` (denied). The token request inside it uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=model-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
API_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
AUTHZ="clients/$API_ID/authz/resource-server"
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=$1 -d password=$1-password | jq -r .access_token"
}
decision() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
```

Use them like this: `decision bob items#delete`, `authz_id policy delete-items`.

To use the Admin Console instead, run `kubectl -n model-demo port-forward svc/keycloak 8080:8080` and open `http://localhost:8080/admin`. Once authorization is switched on, the client `inventory-api` has an **Authorization** tab with resources, scopes, policies, permissions and an **Evaluate** tab, where you pick a user and see which permissions grant.

## Practice tasks

- Switch on authorization for `inventory-api` and list the default objects Keycloak adds.
- Build the scopes, the resource `items`, two role policies and three scope permissions, and check six decisions for `alice` and `bob`.
- Before you run it, predict `decision bob items#delete` when `delete-items` uses both role policies with `AFFIRMATIVE`. Then check.
- Add a scope with no permission and compare the decision in `ENFORCING` and `PERMISSIVE` mode.
- Open the **Evaluate** tab in the Admin Console, evaluate `bob` against `items`, and match its answer to your `decision` results.
