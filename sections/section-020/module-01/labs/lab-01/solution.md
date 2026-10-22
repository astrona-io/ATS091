# Solution: Allow Deletes Only For Staff In Business Hours

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the time policy's hours, the aggregated policy and the `delete-items` permission, and the decisions that do not depend on the clock.

## Step 1: Define the helpers

The token request inside `decision` uses the password grant, which is only for terminal testing.

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
```

## Step 2: Create the group policy and the time policy

```sh
STAFF_ID=$(kcadm get groups -r inventory -q search=staff -q exact=true --fields id --format csv --noquotes | head -n 1)
kcadm create $AUTHZ/policy/group -r inventory -s name=staff-members \
  -s "groups=[{\"id\":\"$STAFF_ID\",\"extendChildren\":false}]"
kcadm create $AUTHZ/policy/time -r inventory -s name=business-hours -s hour=8 -s hourEnd=17
```

## Step 3: Combine them

```sh
kcadm create $AUTHZ/policy/aggregate -r inventory -s name=staff-in-business-hours -s decisionStrategy=UNANIMOUS \
  -s "policies=[\"$(authz_id policy staff-members)\",\"$(authz_id policy business-hours)\"]"
```

## Step 4: Use it in delete-items

```sh
kcadm update $AUTHZ/permission/scope/$(authz_id policy delete-items) -r inventory \
  -s decisionStrategy=UNANIMOUS -s "policies=[\"$(authz_id policy staff-in-business-hours)\"]"
```

## Step 5: Prove it

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- date -u +%H
for user in alice bob; do for scope in view edit delete; do echo "$user $scope $(decision $user items#$scope)"; done; done
```

`bob` gets `200` for `view` and `403` for `edit` and `delete`. `alice` gets `200` for `view` and `edit`. For `delete`, she gets `200` when the hour is between 8 and 17, and `403` outside it.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add both policies to `delete-items` with `AFFIRMATIVE` | Anyone in `staff` may delete at any hour, and anyone may delete during business hours |
| Keep `inventory-managers` in `delete-items` next to the aggregate, with `AFFIRMATIVE` | Every manager may still delete at night |
| A user policy for `alice` instead of the group policy | The next member of `staff` cannot delete |
