# Solution: Copy A Resource Server With Export And Import

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the objects of `inventory-api-v2`, the decisions of both servers, and that `inventory-api` is unchanged.

## Step 1: Define the helpers

The token request inside `decision` uses the password grant, which is only for terminal testing.

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

## Step 2: Look at the target

```sh
kcadm get $TARGET/resource -r inventory --fields name
kcadm get $TARGET/policy -r inventory --fields name,type
```

If the lists show "Default Resource", "Default Policy" or "Default Permission", delete them before the import, because the exported file repeats those names.

```sh
target_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$TARGET/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
for name in "Default Permission" "Default Policy"; do
  id=$(target_id policy "$name"); [ -n "$id" ] && kcadm delete "$TARGET/policy/$id" -r inventory
done
id=$(target_id resource "Default Resource"); [ -n "$id" ] && kcadm delete "$TARGET/resource/$id" -r inventory
```

## Step 3: Export and import

```sh
kcadm get $SOURCE/settings -r inventory | kcadm create $TARGET/import -r inventory -f -
```

## Step 4: Prove it

```sh
for server in inventory-api inventory-api-v2; do
  for user in alice bob; do for scope in view edit delete; do
    echo "$server $user $scope $(decision $user items#$scope $server)"
  done; done
done
```

`alice` gets `200` for all three scopes on both servers. `bob` gets `200` for `view` and `403` for `edit` and `delete` on both.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create every object of `inventory-api-v2` by hand | It works but repeats the work the task asks you to avoid, and a typo makes the copy differ |
| Import without deleting the default objects | The import can clash with objects of the same name |
| Set `PERMISSIVE` on `inventory-api-v2` | `bob` is granted scopes that no permission protects, and the check for `ENFORCING` fails |
