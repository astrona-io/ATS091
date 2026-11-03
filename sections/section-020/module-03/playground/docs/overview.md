# Overview: Decide By Client And Client Scope (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory` and builds the model on `inventory-api`. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`clients-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm `inventory` with the users `alice` (roles `inventory-viewer` and `inventory-manager`) and `bob` (role `inventory-viewer`), with the passwords `alice-password` and `bob-password`.
- The public clients `inventory-cli` and `reports-cli`, both with Direct access grants, and the client scope `inventory-write`, an optional scope of `inventory-cli`.
- The resource server **`inventory-api`** with the client secret `inventory-api-secret` (lab-only), the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. The token request uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=clients-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
AUTHZ="clients/$CLIENT_ID/authz/resource-server"
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
client_uuid() { kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes; }
user_token_via() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=$1 -d scope='openid $3' \
      -d username=$2 -d password=$2-password | jq -r .access_token"
}
decision_via() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token_via "$1" "$2" "$4")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$3" -d response_mode=decision
}
```

## Practice tasks

- Create a client policy for `reports-cli` and prove it from both clients.
- Create a client scope policy for `inventory-write` and ask with and without the scope.
- Make `inventory-write` a default scope of `inventory-cli` and ask again.
- Combine a role policy and a client policy in an aggregated policy.
