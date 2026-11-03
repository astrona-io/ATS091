# Read And Revoke Sharing

When an owner shares a resource, Keycloak stores a **permission ticket**: a record that names a resource, a requester and a scope, and says whether the owner granted it. Sharing is only safe when the owner can take it back. A resource server also needs to show an owner who has access. The Protection API lists tickets and deletes them. This part shares a resource, lists the sharing and revokes one scope without deleting the resource.

## Share a resource

The commands below need these helpers and a PAT. Paste them once in each new terminal. `grant` creates a granted ticket for one user and one scope. The token request for users uses the password grant, which is only for terminal testing.

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
resource_id() {   # resource_id NAME -> id of the resource
  in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set?name=$1&exactName=true" | jq -r '.[0]'
}
grant() {   # grant RESOURCE USER SCOPE -> creates a granted permission ticket
  in_tester curl -s -X POST "$KEYCLOAK/authz/protection/permission/ticket" \
    -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
    -d "{\"resource\":\"$(resource_id "$1")\",\"requester\":\"$(user_uuid "$2")\",\"granted\":true,\"scopeName\":\"$3\"}" | jq -c '{id, granted}'
}
```

Register a shelf for `alice` and share `view` and `edit` with `bob`:

```sh
ALICE_ID=$(user_uuid alice)
in_tester curl -s -X POST "$KEYCLOAK/authz/protection/resource_set" \
  -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
  -d "{\"name\":\"alice-shelf\",\"owner\":\"$ALICE_ID\",\"ownerManagedAccess\":true,\"resource_scopes\":[\"view\",\"edit\"]}" | jq -c '{_id, name}'
grant alice-shelf bob view
grant alice-shelf bob edit
for scope in view edit; do echo "bob $scope $(decision bob alice-shelf#$scope)"; done
```

Both decisions return `200`, because both tickets are granted.

## List the tickets

A `GET` request to `/authz/protection/permission/ticket` lists tickets. The query parameters `resourceId`, `requester`, `owner`, `scopeId` and `granted` narrow the list. The parameter `returnNames=true` adds the readable names of the resource, the requester and the scope. List the tickets of the shelf:

```sh
in_tester curl -s -H "Authorization: Bearer $PAT" \
  "$KEYCLOAK/authz/protection/permission/ticket?resourceId=$(resource_id alice-shelf)&returnNames=true" | jq -c '.[] | {id, scopeName, requesterName, granted}'
```

The answer has one line for each ticket: the ticket `id`, the scope, the requester and the flag `granted`. An application uses this list to show the owner a page with the title "who can use this".

## Revoke one scope

The owner decides that `bob` may keep reading but may not change the shelf. To revoke one scope, delete its ticket. A `DELETE` request to `/authz/protection/permission/ticket/<id>` removes it. Find the id of the `edit` ticket and delete it:

```sh
EDIT_TICKET=$(in_tester curl -s -H "Authorization: Bearer $PAT" \
  "$KEYCLOAK/authz/protection/permission/ticket?resourceId=$(resource_id alice-shelf)&returnNames=true" | jq -r '.[] | select(.scopeName=="edit") | .id')
in_tester curl -s -o /dev/null -w '%{http_code}\n' -X DELETE -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/permission/ticket/$EDIT_TICKET"
for scope in view edit; do echo "bob $scope $(decision bob alice-shelf#$scope)"; done
```

The delete returns `204`. `bob` now gets `200` for `view` and `403` for `edit`. The resource still exists, the owner still has full access, and the ticket for `view` is untouched. Deleting the resource would have removed the sharing for every user, which is more than the owner asked for.

You can now show an owner who has access and take back one scope without side effects. Sharing, like every other part of the model, is data that the resource server reads and changes through one interface. The remaining question is how the API code that sits in front of all this learns which paths and scopes it must check.

## Common pitfalls

> [!WARNING]
> - **Deleting the resource to revoke one scope.** This removes access for everyone. Delete only the ticket.
> - **Looking for the ticket by name.** A ticket has an id. List with `returnNames=true` and select by `scopeName`.
> - **Listing tickets without `resourceId`.** The answer then holds the tickets of every resource of the resource server.
> - **Expecting a revoked scope to leave a cached token.** An RPT that was issued before the revoke can still carry the scope until it expires.

## Your mission: Register A Resource And Revoke One Scope

You can now register a resource with the Protection API and revoke one scope of a sharing without touching the rest. The graded lab gives you a shelf that `alice` shared fully with `bob`, and asks you to register a second resource for her and to reduce the sharing of the shelf to `view`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-091-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-091-lab-030-02
astrona start ats-091-playground-030-02
```
