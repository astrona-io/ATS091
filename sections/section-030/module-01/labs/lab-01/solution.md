# Solution: Make The API Refuse Deletes For Viewers

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: seven requests to `inventory-api`, that the API's code and settings are unchanged, and the model (`ENFORCING`, `delete-items` on `inventory-managers`, `bob` still a viewer).

## Step 1: Define the helpers and reproduce the problem

The token request uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=uma-demo
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
for user in alice bob; do for method in GET POST DELETE; do echo "$user $method $(call_api $user $method)"; done; done
```

`bob` gets `200` for `DELETE`. Everything else matches the table.

## Step 2: Ask Keycloak the same question directly

```sh
kubectl -n "$NAMESPACE" logs deploy/inventory-api --tail=6
in_tester curl -s -o /dev/null -w '%{http_code}\n' $KEYCLOAK/protocol/openid-connect/token \
  -H "Authorization: Bearer $(user_token bob)" \
  -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
  -d audience=inventory-api -d permission=items#delete -d response_mode=decision
```

The log shows `scope=delete decision=granted` for `bob`'s `DELETE`, and Keycloak answers `200` when asked directly. The API asked the right question and enforced the answer; the model is wrong.

## Step 3: Read the delete permission

```sh
kcadm get $AUTHZ/policy/$(authz_id policy delete-items)/associatedPolicies -r inventory --fields name,type
```

`delete-items` uses `inventory-viewers`, the role policy for viewers.

## Step 4: Fix it

```sh
kcadm update $AUTHZ/permission/scope/$(authz_id policy delete-items) -r inventory \
  -s decisionStrategy=UNANIMOUS -s "policies=[\"$(authz_id policy inventory-managers)\"]"
for user in alice bob; do for method in GET POST DELETE; do echo "$user $method $(call_api $user $method)"; done; done
in_tester curl -s -o /dev/null -w '%{http_code}\n' http://inventory-api:3000/items
```

`alice` gets `200` three times, `bob` gets `200` for `GET` and `403` for `POST` and `DELETE`, and the request without a token gets `401`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the API so `DELETE` needs a different scope | The task forbids changing the API, and the model would still let viewers delete through any other client |
| Remove `inventory-viewer` from `bob` | `bob` can no longer read items |
| Add `inventory-managers` next to `inventory-viewers` with `AFFIRMATIVE` | Viewers still pass through the viewer policy |
