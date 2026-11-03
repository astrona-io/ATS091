# Owners And Owner-Managed Access

Every resource has an owner. For a resource that the administrator creates, the owner is the resource server and nobody notices. For a resource that belongs to a person, such as a shelf or a document, the owner decides who else may use it. This changes the decision: the owner is always granted, and everybody else needs a permission or a grant from the owner. This part registers a resource for a user and reads the effect in two decisions.

## Who owns a resource

The field `owner` holds the id of a user or of a client. When you create a resource in the Admin Console or with `kcadm.sh`, Keycloak sets the owner to the resource server. When the resource server registers the resource with the Protection API, it can set `owner` to the id of the user who created the thing. The field `ownerManagedAccess` then tells Keycloak whether the owner may share it. Sharing needs the realm setting **User-managed access**, which is on in the playground.

The commands below need these helpers. Paste them once in each new terminal. `pat` returns a protection API token (PAT), an access token with the scope `uma_protection` that the resource server gets with the client credentials grant:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=resources-demo
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
decision() {   # decision bob album-alice#view -> 200 (granted) or 403 (denied)
  in_tester curl -s -o /dev/null -w '%{http_code}\n' $KEYCLOAK/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
PAT=$(pat)
```

The token request in `user_token` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. The client secret `inventory-api-secret` is a lab-only value.

## Register a resource for a user

Register the resource `album-alice` for `alice` with the scope `view`. No permission is created for it:

```sh
ALICE_ID=$(user_uuid alice)
in_tester curl -s -X POST "$KEYCLOAK/authz/protection/resource_set" \
  -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
  -d "{\"name\":\"album-alice\",\"owner\":\"$ALICE_ID\",\"ownerManagedAccess\":true,\"resource_scopes\":[\"view\"]}" | jq '{_id, name}'
```

Ask for a decision for the owner and for `bob`:

```sh
echo "alice $(decision alice album-alice#view)"
echo "bob $(decision bob album-alice#view)"
```

`alice` gets `200` and `bob` gets `403`. The owner is granted without any policy, because the owner of a resource always has access to it. `bob` is a viewer in the realm, but no permission covers `album-alice` and the enforcement mode is `ENFORCING`, so Keycloak denies him. Owning a resource is the only reason `alice` passes.

## Read the owner

Read the resource through the Protection API and look at the owner:

```sh
ALBUM_ID=$(in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set?name=album-alice&exactName=true" | jq -r '.[0]')
in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$ALBUM_ID" | jq '{name, owner, ownerManagedAccess}'
```

The owner is the user id of `alice`. If `ownerManagedAccess` were `false`, `alice` would still own the resource, but she could not share it. Only the administrator could add a permission for `bob`.

You can now say who owns a resource, why the owner passes and why another user does not, and you can register a resource for a user. The module closes here: you can describe a resource, group resources by type, choose the right kind of permission and place the resource with its owner.

## Common pitfalls

> [!WARNING]
> - **Expecting a role to override ownership rules.** A viewer role does not grant `bob` a resource that has no permission covering it.
> - **Creating user resources in the Admin Console.** The owner becomes the resource server, and the user cannot share it.
> - **Forgetting `ownerManagedAccess`.** Without it the owner cannot share the resource.
> - **Using a user name as `owner`.** The field takes the user id.
