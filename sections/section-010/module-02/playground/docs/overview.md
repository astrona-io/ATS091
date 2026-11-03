# Overview: Know The Architecture And Manage Resource Server Settings (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory`, builds the authorization model on `inventory-api` and adds a second resource server, `inventory-api-v2`, with no model. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`settings-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm **`inventory`** with `alice` (roles `inventory-viewer` and `inventory-manager`) and `bob` (role `inventory-viewer`). Passwords are `alice-password` and `bob-password`.
- The resource server **`inventory-api`** with the resource `items`, the scopes `view`, `edit` and `delete`, two role policies and three scope permissions, in `ENFORCING` mode.
- The confidential client **`inventory-api-v2`** with authorization switched on and no model of its own.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. The token request inside `user_token` uses the password grant, which is only for terminal testing. `decision` takes the resource server as an optional third argument.

```sh
NAMESPACE=settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
SOURCE_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
TARGET_ID=$(kcadm get clients -r inventory -q clientId=inventory-api-v2 --fields id --format csv --noquotes)
SOURCE="clients/$SOURCE_ID/authz/resource-server"
TARGET="clients/$TARGET_ID/authz/resource-server"
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
    -d audience="${3:-inventory-api}" -d permission="$2" -d response_mode=decision
}
```

## Practice tasks

- Change the enforcement mode, the decision strategy and remote resource management of `inventory-api`, and prove each change with a decision.
- Export the settings of `inventory-api`, read them with `jq`, and import them into `inventory-api-v2`. Compare the decisions of both servers.
- Add a scope and a permission to `inventory-api`, export again and compare the two files with `diff`.
