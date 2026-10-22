# Solution: Close A Resource Server That Allows Too Much

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the mode is `ENFORCING`, six decisions match the table, and `delete-items` is the original permission while the users keep their roles.

## Step 1: Define the helpers and look at the behaviour

```sh
NAMESPACE=modelcapstone-demo
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
for user in alice bob; do for scope in view edit delete; do echo "$user $scope $(decision $user items#$scope)"; done; done
```

Every decision is `200`, including `bob` for `edit` and `delete`. Something lets everything through.

## Step 2: Read the resource server and the permissions

```sh
kcadm get $AUTHZ -r inventory --fields policyEnforcementMode,decisionStrategy
kcadm get $AUTHZ/permission -r inventory --fields name,decisionStrategy
kcadm get $AUTHZ/policy/$(authz_id policy delete-items)/associatedPolicies -r inventory --fields name
```

Three facts come out:

- The mode is `PERMISSIVE`, so a request that no permission covers is granted.
- There is no `edit-items` permission, so `edit` is covered by nothing, and `PERMISSIVE` grants it to everyone.
- `delete-items` uses `inventory-managers` **and** `inventory-viewers` with the strategy `AFFIRMATIVE`, so the viewer policy alone is enough to delete.

## Step 3: Correct delete-items in place

```sh
kcadm update $AUTHZ/permission/scope/$(authz_id policy delete-items) -r inventory \
  -s decisionStrategy=UNANIMOUS -s "policies=[\"$(authz_id policy inventory-managers)\"]"
echo "bob delete $(decision bob items#delete)"
```

`bob` now gets `403` for `delete`.

## Step 4: Write the missing edit permission

```sh
kcadm create $AUTHZ/permission/scope -r inventory -s name=edit-items -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource items)\"]" -s "scopes=[\"$(authz_id scope edit)\"]" \
  -s "policies=[\"$(authz_id policy inventory-managers)\"]"
```

## Step 5: Switch back to ENFORCING and prove it

```sh
kcadm update $AUTHZ -r inventory -s policyEnforcementMode=ENFORCING
for user in alice bob; do for scope in view edit delete; do echo "$user $scope $(decision $user items#$scope)"; done; done
```

`alice` gets `200` three times; `bob` gets `200` for `view` and `403` for `edit` and `delete`. The order of steps 4 and 5 matters in practice: switching to `ENFORCING` first would deny `edit` to `alice` until the permission exists.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove `inventory-viewer` from `bob` | He can no longer view items, and the grader requires his role |
| Delete `delete-items` and create a new one | The decisions are right, but the grader requires the original permission |
| Keep `PERMISSIVE` and only fix `delete-items` | `edit` stays open to everyone, because no permission covers it |
