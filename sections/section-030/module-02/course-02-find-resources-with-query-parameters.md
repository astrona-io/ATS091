# Find Resources With Query Parameters

After an application registers thousands of resources, it cannot read them all to find one. A page that lists the resources of one user, or one type, or one URI, needs a search. The list call of the Protection API takes query parameters for this. This part registers three resources and runs the searches an application makes.

## What the list call returns

A `GET` request to `/authz/protection/resource_set` returns a JSON list of resource ids. It does not return the resources themselves. This keeps the answer small. To get the whole resource, pass the id to the read call, or add the parameter `deep=true`, which returns the full resources in the list.

The query parameters narrow the list:

| Parameter | What it matches |
| --- | --- |
| `name` | Resources whose name contains the text |
| `exactName` | `true` makes `name` match the full name only |
| `uri` | The URI of the resource |
| `owner` | The owner, as a user id |
| `type` | The resource type |
| `scope` | The name of a scope the resource has |
| `first` and `max` | The first result and the largest number of results, for paging |
| `deep` | `true` returns the full resources |

## Register three resources

The commands below need these helpers and a PAT. Paste them once in each new terminal. `register` registers a resource for an owner with a name, a type and a list of scopes. The token request for users uses the password grant, which is only for terminal testing.

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
pat() {
  in_tester sh -c "curl -s $KEYCLOAK/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-api \
    -d client_secret=inventory-api-secret | jq -r .access_token"
}
PAT=$(pat)
register() {   # register NAME OWNER TYPE SCOPE... -> the id of the new resource
  local name="$1" owner_id type="$3" scopes="" scope
  owner_id="$(user_uuid "$2")"
  shift 3
  for scope in "$@"; do scopes="$scopes\"$scope\","; done
  in_tester curl -s -X POST "$KEYCLOAK/authz/protection/resource_set" \
    -H "Authorization: Bearer $PAT" -H 'Content-Type: application/json' \
    -d "{\"name\":\"$name\",\"type\":\"$type\",\"uris\":[\"/$name\"],\"owner\":\"$owner_id\",\"ownerManagedAccess\":true,\"resource_scopes\":[${scopes%,}]}" | jq -r '._id'
}
find_resources() {   # find_resources QUERY -> names of the matching resources
  local id
  for id in $(in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set?$1" | jq -r '.[]'); do
    in_tester curl -s -H "Authorization: Bearer $PAT" "$KEYCLOAK/authz/protection/resource_set/$id" | jq -r '.name'
  done
}
```

Register a shelf and a notebook for `alice`, and a shelf for `bob`:

```sh
register alice-shelf alice urn:inventory-api:resources:shelf view edit
register alice-notebook alice urn:inventory-api:resources:note view
register bob-shelf bob urn:inventory-api:resources:shelf view
```

## Search

Each search below returns the names of the matching resources. Search by part of the name, then by exact name:

```sh
find_resources "name=shelf"
find_resources "name=alice-shelf&exactName=true"
```

The first search returns `alice-shelf` and `bob-shelf`, because both names contain `shelf`. The second returns `alice-shelf` only. Search by owner, which is the question "show me the resources of this user":

```sh
find_resources "owner=$(user_uuid alice)"
```

The search returns `alice-shelf` and `alice-notebook`. Search by type, then by scope:

```sh
find_resources "type=urn:inventory-api:resources:shelf"
find_resources "scope=edit"
```

The type search returns both shelves. The scope search returns `alice-shelf`, the only resource with the scope `edit` among these three. You can combine parameters, and the result holds only the resources that match all of them:

```sh
find_resources "type=urn:inventory-api:resources:shelf&owner=$(user_uuid bob)"
```

The combined search returns `bob-shelf`. Add `first=0&max=1` to a query and the list holds at most one id, which is how an application pages through a long result.

You can now find the resources an application needs without reading all of them, and you know that the list call returns ids. The searches work on what the resource server registered. The next question is what the users have done with those resources: who got access, and how to take it back.

## Common pitfalls

> [!WARNING]
> - **Treating the list as full resources.** The list holds ids. Read each id, or add `deep=true`.
> - **Searching a name without `exactName`.** The search matches part of a name, so `shelf` finds every resource with `shelf` in its name.
> - **Searching by owner name.** The `owner` parameter takes a user id. Look it up first.
> - **Forgetting paging.** A long list is cut at the default size. Use `first` and `max`.
