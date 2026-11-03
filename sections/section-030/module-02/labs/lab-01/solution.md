# Solution: Register A Resource And Revoke One Scope

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the resource `alice-notes`, the decisions of `bob` on `alice-shelf`, and the tickets that remain on `alice-shelf`.

## Step 1: Define the helpers

The token request inside `user_token` uses the password grant, which is only for terminal testing.

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
resource_id() {
  in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set?name=$1&exactName=true" | jq -r '.[0]'
}
```

## Step 2: Register alice-notes

```sh
ALICE_ID=$(user_uuid alice)
in_tester curl -s -X POST "$KEYCLOAK/authz/protection/resource_set" \
  -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
  -d "{\"name\":\"alice-notes\",\"owner\":\"$ALICE_ID\",\"ownerManagedAccess\":true,\"resource_scopes\":[\"view\"]}" | jq -c '{_id, name}'
```

## Step 3: Revoke the edit ticket

List the tickets of the shelf, select the one for `edit` and delete it. Do not delete the resource and do not delete the `view` ticket.

```sh
SHELF_ID=$(resource_id alice-shelf)
EDIT_TICKET=$(in_tester curl -s -H "Authorization: Bearer $PAT" \
  "$KEYCLOAK/authz/protection/permission/ticket?resourceId=$SHELF_ID&returnNames=true" | jq -r '.[] | select(.scopeName=="edit") | .id')
in_tester curl -s -o /dev/null -w '%{http_code}\n' -X DELETE -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/permission/ticket/$EDIT_TICKET"
```

## Step 4: Prove it

```sh
for target in alice-notes#view alice-shelf#view alice-shelf#edit; do
  echo "alice $target $(decision alice $target)"
  echo "bob $target $(decision bob $target)"
done
```

`alice` gets `200` everywhere, because she owns both resources. `bob` gets `403` for `alice-notes#view`, `200` for `alice-shelf#view` and `403` for `alice-shelf#edit`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `alice-shelf` and register it again | The sharing is lost and the check for the `view` ticket fails |
| Delete both tickets | `bob` loses `view` too |
| Share nothing and give `bob` a role | The change is not made where the sharing is stored, and the ticket check fails |
