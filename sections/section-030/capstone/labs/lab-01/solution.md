# Solution: Make The Inventory API Enforce Its Rules

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: seven requests to `inventory-api`, that the API's code is unchanged and its audience is `inventory-api`, and the model.

## Step 1: Define the helpers and look at the answers

The token request uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=umacapstone-demo
KEYCLOAK=http://keycloak:8080/realms/inventory
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
in_tester() { kubectl -n "$NAMESPACE" exec deploy/tester -- "$@"; }
user_token() {
  in_tester sh -c "curl -s $KEYCLOAK/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=$1 -d password=$1-password | jq -r .access_token"
}
call_api() {
  in_tester curl -s -o /dev/null -w '%{http_code}\n' \
    -X "$2" -H "Authorization: Bearer $(user_token "$1")" http://inventory-api:3000/items
}
decision() {
  in_tester curl -s -o /dev/null -w '%{http_code}\n' $KEYCLOAK/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
for user in alice bob; do for method in GET POST DELETE; do echo "$user $method $(call_api $user $method)"; done; done
kubectl -n "$NAMESPACE" logs deploy/inventory-api --tail=6
```

No request gets `200`. The log shows errors or denials for every request, not the decisions the rules expect.

## Step 2: Check the API's settings

```sh
kubectl -n "$NAMESPACE" get deployment inventory-api -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

`KEYCLOAK_AUDIENCE` is `inventory-web`, a client that is not the resource server. The API asks Keycloak about the wrong resource server. Fix the setting; the code stays as it is:

```sh
kubectl -n "$NAMESPACE" set env deployment/inventory-api KEYCLOAK_AUDIENCE=inventory-api
kubectl -n "$NAMESPACE" rollout status deployment/inventory-api
for user in alice bob; do for method in GET POST DELETE; do echo "$user $method $(call_api $user $method)"; done; done
```

Some answers change, but not all are right: `bob` gets `403` for `GET`, and `alice` does not get `200` for `POST` (a `403`, or a `502` if Keycloak rejects the request as invalid).

## Step 3: Ask Keycloak directly

```sh
for scope in view edit delete; do echo "alice $scope $(decision alice items#$scope) bob $scope $(decision bob items#$scope)"; done
```

Keycloak gives the same answers as the API, so the rest is in the model.

## Step 4: Read and fix the model

```sh
kcadm get $AUTHZ/resource/$(authz_id resource items)/scopes -r inventory --fields name
kcadm get $AUTHZ/policy/$(authz_id policy view-items)/associatedPolicies -r inventory --fields name
```

The resource `items` lists only `view` and `delete`, so nothing can grant `edit` on it. `view-items` uses `inventory-managers`, so viewers cannot read. Fix both:

```sh
kcadm update $AUTHZ/resource/$(authz_id resource items) -r inventory \
  -s "scopes=[{\"name\":\"view\"},{\"name\":\"edit\"},{\"name\":\"delete\"}]"
kcadm update $AUTHZ/permission/scope/$(authz_id policy view-items) -r inventory \
  -s decisionStrategy=UNANIMOUS -s "policies=[\"$(authz_id policy inventory-viewers)\"]"
```

Ask Keycloak again:

```sh
for scope in view edit delete; do echo "alice $scope $(decision alice items#$scope)"; done
kcadm get $AUTHZ/policy/$(authz_id policy edit-items)/scopes -r inventory --fields name
```

`alice` still cannot `edit`, and `edit-items` lists no scopes. When a scope is taken off a resource, Keycloak also takes it off every permission that used it, and putting the scope back on the resource does not restore those links. Give `edit-items` its scope again:

```sh
kcadm update $AUTHZ/permission/scope/$(authz_id policy edit-items) -r inventory \
  -s "scopes=[\"$(authz_id scope edit)\"]"
```

## Step 5: Prove it

```sh
for user in alice bob; do for method in GET POST DELETE; do echo "$user $method $(call_api $user $method)"; done; done
in_tester curl -s -o /dev/null -w '%{http_code}\n' http://inventory-api:3000/items
```

`alice` gets `200` three times; `bob` gets `200` for `GET` and `403` for `POST` and `DELETE`; the request without a token gets `401`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change `PROTECTED_RESOURCE` or the code to work around the model | The task forbids changing the code, and the model stays wrong for every other client |
| Switch to `PERMISSIVE` | `edit` is granted to everyone, because no scope `edit` on `items` is covered by a permission |
| Give `bob` the role `inventory-manager` | `bob` can read, but also edit and delete |
