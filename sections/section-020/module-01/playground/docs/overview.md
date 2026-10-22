# Overview: Write Policies That Decide Access (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory` and builds a role-based authorization model on `inventory-api`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`policies-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm **`inventory`** with `alice` (roles `inventory-viewer` and `inventory-manager`, group `staff`, `alice@example.com`) and `bob` (role `inventory-viewer`, no group, `bob@example.com`). Passwords are `alice-password` and `bob-password`.
- The resource server **`inventory-api`** with the resource `items` (scopes `view`, `edit`, `delete`), the role policies `inventory-viewers` and `inventory-managers`, and the scope permissions `view-items`, `edit-items` and `delete-items`, in `ENFORCING` mode.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `use_policy` swaps the policies of the permission `audit-items` and prints both users' decisions for `items#audit`; it needs the scope `audit` and the permission `audit-items`, which you create in the first practice task. The token request inside `decision` uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=policies-demo
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
use_policy() {
  kcadm update $AUTHZ/permission/scope/$(authz_id policy audit-items) -r inventory \
    -s "policies=[\"$(authz_id policy "$1")\"]"
  echo "alice $(decision alice items#audit) bob $(decision bob items#audit)"
}
```

## Practice tasks

- Create the scope `audit`, add it to `items`, and protect it with a permission `audit-items` that uses `inventory-viewers`. Then try a user policy, a group policy, a client policy and a regex policy with `use_policy`.
- Set a group policy to `NEGATIVE` and predict both users' decisions before you check.
- Create a time policy for the current UTC hour only (check it with `kubectl -n policies-demo exec deploy/tester -- date -u +%H`), and another one for a different hour. Compare.
- Combine a group policy and a time policy in an aggregated policy, first with `UNANIMOUS`, then with `AFFIRMATIVE`, and explain the difference for `bob`.
- Ask for `response_mode=permissions` for each user and compare the lists.
