# Solution: Model The Inventory API As A Resource Server

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the resource server is `ENFORCING` and `items` lists the three scopes, six decisions for `alice` and `bob` come out as the table says, and each permission uses role policies only.

## Step 1: Define the helpers and sign in

Every step uses the same helpers. `authz_id` looks up the id of a scope, resource or policy by name, because Keycloak objects refer to each other by id. The token request inside `decision` uses the password grant, which is only for testing from a terminal.

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

## Step 2: Switch on authorization

```sh
kcadm update clients/$API_ID -r inventory -s authorizationServicesEnabled=true
kcadm get $AUTHZ -r inventory --fields policyEnforcementMode
```

The mode is `ENFORCING`, the default. Leave it.

## Step 3: Create the scopes and the resource

```sh
for scope in view edit delete; do kcadm create $AUTHZ/scope -r inventory -s name=$scope; done
kcadm create $AUTHZ/resource -r inventory -s name=items \
  -s type=urn:inventory-api:resources:item -s 'uris=["/items","/items/*"]' \
  -s "scopes=[{\"id\":\"$(authz_id scope view)\"},{\"id\":\"$(authz_id scope edit)\"},{\"id\":\"$(authz_id scope delete)\"}]"
kcadm get $AUTHZ/resource/$(authz_id resource items)/scopes -r inventory --fields name
```

The last command lists `view`, `edit` and `delete`.

## Step 4: Create the role policies

```sh
kcadm create $AUTHZ/policy/role -r inventory -s name=inventory-viewers -s logic=POSITIVE \
  -s "roles=[{\"id\":\"$(kcadm get roles/inventory-viewer -r inventory --fields id --format csv --noquotes)\",\"required\":false}]"
kcadm create $AUTHZ/policy/role -r inventory -s name=inventory-managers -s logic=POSITIVE \
  -s "roles=[{\"id\":\"$(kcadm get roles/inventory-manager -r inventory --fields id --format csv --noquotes)\",\"required\":false}]"
```

## Step 5: Create the scope permissions

```sh
ITEMS_ID=$(authz_id resource items)
kcadm create $AUTHZ/permission/scope -r inventory -s name=view-items -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$ITEMS_ID\"]" -s "scopes=[\"$(authz_id scope view)\"]" \
  -s "policies=[\"$(authz_id policy inventory-viewers)\"]"
kcadm create $AUTHZ/permission/scope -r inventory -s name=edit-items -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$ITEMS_ID\"]" -s "scopes=[\"$(authz_id scope edit)\"]" \
  -s "policies=[\"$(authz_id policy inventory-managers)\"]"
kcadm create $AUTHZ/permission/scope -r inventory -s name=delete-items -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$ITEMS_ID\"]" -s "scopes=[\"$(authz_id scope delete)\"]" \
  -s "policies=[\"$(authz_id policy inventory-managers)\"]"
```

## Step 6: Prove the decisions

```sh
for user in alice bob; do for scope in view edit delete; do echo "$user $scope $(decision $user items#$scope)"; done; done
```

`alice` gets `200` three times. `bob` gets `200` for `view` and `403` for `edit` and `delete`.

## Step 7: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A user policy that names `alice` for edit and delete | The decisions come out right today, but the next manager gets nothing; the grader requires role policies |
| One resource-based permission for all of `items` | Every scope gets the same rule, so `bob` either may do everything or nothing |
| `PERMISSIVE` mode instead of the `view-items` permission | `view` is granted, but so is every scope anyone adds later |

## Common mistakes

- Passing a role name where the role policy expects the role's id.
- Creating the resource before the scopes, then listing scopes that do not exist.
- Forgetting `audience=inventory-api` in the decision request.
