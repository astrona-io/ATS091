# Resource Permissions And Scope Permissions

A permission that grants "viewing" and quietly grants "deleting" is a serious fault, and it does not show in the Admin Console as an error. Keycloak has two kinds of permission, and they answer different questions. A resource-based permission answers "who may use this resource?". A scope-based permission answers "who may do this action on this resource?". This part shows the difference with one decision request for each.

## What a resource-based permission grants

A resource-based permission protects whole resources. It has no scopes, so it makes no distinction between actions. When a user passes its policies, the user gets every scope of the resource.

The commands below need these helpers. Paste them once in each new terminal:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=resources-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
AUTHZ="clients/$CLIENT_ID/authz/resource-server"
authz_id() {   # authz_id resource|scope|policy NAME -> the object's id
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
decision() {   # decision bob tray-1#delete -> 200 (granted) or 403 (denied)
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
```

The token request in `user_token` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. Create a resource `tray-1` with three scopes, and a resource-based permission that gives it to the viewers:

```sh
kcadm create "$AUTHZ/resource" -r inventory -s name=tray-1 \
  -s 'scopes=[{"name":"view"},{"name":"edit"},{"name":"delete"}]'
kcadm create "$AUTHZ/permission/resource" -r inventory \
  -s name=use-tray-1 -s type=resource -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource tray-1)\"]" \
  -s "policies=[\"$(authz_id policy inventory-viewers)\"]"
```

Ask what `bob`, a viewer, may do:

```sh
for scope in view edit delete; do echo "bob tray-1#$scope $(decision bob tray-1#$scope)"; done
```

All three answers are `200`. The permission names the resource and no scope, so the policy `inventory-viewers` unlocks every scope, including `delete`. The name `use-tray-1` hides that a viewer can delete.

## What a scope-based permission grants

A scope-based permission names the scopes it covers. A user gets only those scopes. Remove the resource-based permission and create a scope-based permission for `view`:

```sh
kcadm delete "$AUTHZ/policy/$(authz_id policy use-tray-1)" -r inventory
kcadm create "$AUTHZ/permission/scope" -r inventory \
  -s name=view-tray-1 -s type=scope -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource tray-1)\"]" \
  -s "scopes=[\"$(authz_id scope view)\"]" \
  -s "policies=[\"$(authz_id policy inventory-viewers)\"]"
for scope in view edit delete; do echo "bob tray-1#$scope $(decision bob tray-1#$scope)"; done
```

The answers are `200`, `403` and `403`. `bob` may view the tray and may not edit or delete it. A scope that no permission names is denied, because the enforcement mode is `ENFORCING`.

## Choose the kind on purpose

Use a resource-based permission when the action does not matter, for example "only staff may see anything about this resource". Use a scope-based permission when the actions differ, which is the case for almost every API with `GET`, `POST` and `DELETE`. When you cannot decide, choose the scope-based permission. It names what it grants, so a reader of the model sees the risk.

You can now tell what each kind of permission grants and prove it with one decision per scope. Both kinds find the resource by a name or a type that the model holds, and the last question is whose resource it is.

## Common pitfalls

> [!WARNING]
> - **Reading a permission name as its meaning.** `use-tray-1` grants every scope. Read the permission, not only its name.
> - **Testing only the scope you want to grant.** Also ask for the scopes you do not want to grant.
> - **Forgetting that a scope must belong to the resource.** A scope permission names scopes that the resource has. Otherwise Keycloak answers with an error about a scope that is not associated with the resources.
> - **Fixing an over-grant with `PERMISSIVE`.** The enforcement mode does not narrow a permission.
