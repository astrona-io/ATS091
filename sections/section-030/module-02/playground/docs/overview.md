# Overview: Manage Resources With The Protection API (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory` with user-managed access switched on and builds the model on `inventory-api`. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`protection-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm `inventory` with user-managed access on, the users `alice` (roles `inventory-viewer` and `inventory-manager`) and `bob` (role `inventory-viewer`) with the passwords `alice-password` and `bob-password`.
- The resource server **`inventory-api`** with the client secret `inventory-api-secret` (lab-only), the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. The token request for users uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=protection-demo
KEYCLOAK=http://keycloak:8080/realms/inventory
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
in_tester() { kubectl -n "$NAMESPACE" exec deploy/tester -- "$@"; }
user_uuid() { kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes; }
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
decision() {
  in_tester curl -s -o /dev/null -w '%{http_code}\n' $KEYCLOAK/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
PAT=$(pat)
```

## Practice tasks

- Register a resource for each user, change one with a `PUT` request and delete the other.
- Search the resources by owner, type, scope and URI.
- Share a resource with a permission ticket, list the tickets, revoke one scope and prove the change with decisions.
- Fetch the adapter configuration of `inventory-api` and write a `paths` entry for `/items/*`.
