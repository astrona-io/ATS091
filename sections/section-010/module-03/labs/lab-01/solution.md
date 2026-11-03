# Solution: Fix A Resource That No Permission Covers

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the decisions of `bob`, the type of `shelf-c`, and the list of permissions.

## Step 1: Define the helpers

The token request inside `user_token` uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=resources-demo
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

## Step 2: Compare the resources

```sh
for name in shelf-a shelf-c; do
  kcadm get "$AUTHZ/resource/$(authz_id resource $name)" -r inventory --fields name,type
done
```

`shelf-a` has the type `urn:inventory-api:resources:shelf`. `shelf-c` has no type. The permission `view-shelves` protects the shelf type, so it never finds `shelf-c`.

## Step 3: Set the type

```sh
kcadm update "$AUTHZ/resource/$(authz_id resource shelf-c)" -r inventory -s type=urn:inventory-api:resources:shelf
```

## Step 4: Prove it

```sh
for name in shelf-a shelf-b shelf-c vault; do echo "bob $name $(decision bob $name)"; done
```

`bob` gets `200` for the three shelves and `403` for `vault`, because the vault has another type.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a permission for `shelf-c` | The permissions check fails, and the next untyped shelf is missed again |
| Set the enforcement mode to `PERMISSIVE` | `bob` is granted the vault too |
| Change `view-shelves` to cover every type | `bob` is granted the vault |
