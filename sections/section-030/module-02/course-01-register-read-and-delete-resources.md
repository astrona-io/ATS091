# Register, Read And Delete Resources

An application that stores shelves, documents or albums creates a new thing to protect every time a user creates one. If an administrator must add each of them to Keycloak by hand, the application is blocked. The Protection API lets the resource server register a resource itself, change it when the application changes it and delete it when the application deletes it. This part runs the full life cycle of one resource.

## Get a protection API token

The Protection API accepts only a **protection API token (PAT)**. A PAT is an access token that carries the scope `uma_protection`. Keycloak gives the service account of every resource server the role `uma_protection`, so the resource server gets a PAT with the client credentials grant: its own client ID and its client secret. The helper `pat` below does that. The token request for users inside `user_token` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow.

<!-- astrona:playground:renew -->

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
```

The client secret `inventory-api-secret` is a lab-only value. A real resource server keeps its secret in a secret store.

## Register a resource

A resource is registered with a `POST` request to `/authz/protection/resource_set`. The body names the resource, the scopes it supports (`resource_scopes`), its `uris` and its `type`. A user-owned resource also has an `owner`, which is a user id. Register the resource `alice-notes` for `alice`:

```sh
ALICE_ID=$(user_uuid alice)
in_tester curl -s -X POST "$KEYCLOAK/authz/protection/resource_set" \
  -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
  -d "{\"name\":\"alice-notes\",\"type\":\"urn:inventory-api:resources:note\",\"uris\":[\"/notes/alice\"],\"owner\":\"$ALICE_ID\",\"ownerManagedAccess\":true,\"resource_scopes\":[\"view\",\"edit\"]}" | jq '{_id, name}'
```

The answer contains the new `_id` and the name. Keep the id for the next calls. The Protection API returns plain ids when you list resources, so ask for the id by name:

```sh
NOTES_ID=$(in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set?name=alice-notes&exactName=true" | jq -r '.[0]')
echo "$NOTES_ID"
```

## Read and update the resource

A `GET` request to `/authz/protection/resource_set/<id>` returns the whole resource:

```sh
in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$NOTES_ID" | jq '{name, type, uris, resource_scopes}'
```

A `PUT` request to the same path replaces the resource with the body you send. Send the full body, because fields you leave out are cleared. The next request adds the scope `delete` and a second URI:

```sh
in_tester curl -s -X PUT "$KEYCLOAK/authz/protection/resource_set/$NOTES_ID" \
  -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
  -d "{\"name\":\"alice-notes\",\"type\":\"urn:inventory-api:resources:note\",\"uris\":[\"/notes/alice\",\"/notes/alice/*\"],\"owner\":\"$ALICE_ID\",\"ownerManagedAccess\":true,\"resource_scopes\":[\"view\",\"edit\",\"delete\"]}"
in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$NOTES_ID" | jq '.uris'
```

The list of URIs now has two entries. The owner `alice` has access to the resource, and `bob` has none:

```sh
for user in alice bob; do echo "$user $(decision $user alice-notes#view)"; done
```

## Delete the resource

A `DELETE` request removes the resource. The answer is HTTP `204` with no body:

```sh
in_tester curl -s -o /dev/null -w '%{http_code}\n' -X DELETE -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$NOTES_ID"
in_tester curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$NOTES_ID"
```

The first request returns `204` and the second returns `404`, because the resource is gone. An application must delete the Keycloak resource whenever it deletes its own record. A resource left behind keeps its sharing and clutters the list.

You can now register a resource, read it, change it and delete it with a PAT. The resource server owns this life cycle, not the user and not the administrator. When an application has many resources, it needs to find the right one quickly. That is a question of query parameters.

## Common pitfalls

> [!WARNING]
> - **Calling the Protection API with a user token.** It needs the PAT of the resource server, with the scope `uma_protection`.
> - **Sending a partial body in a `PUT` request.** The request replaces the resource. Fields that you leave out are cleared.
> - **Registering a scope that the resource server does not know.** Keycloak creates a scope with that name. Check the names to avoid typing mistakes such as `veiw`.
> - **Leaving resources behind.** Delete the Keycloak resource when the application deletes its own record.
