# Describe A Resource

A permission can only protect what the model describes. When a resource is described badly, the permission either misses it or covers it in a way nobody planned. Before the rules, you need the fields. This part creates one resource with every common field, reads it back and changes one field.

## The fields of a resource

A resource has these fields in the Admin REST API:

| Field | What it holds |
| --- | --- |
| `name` | A unique name inside the resource server. Permissions and decision requests use it |
| `displayName` | A readable name for people, for example in the Account Console |
| `type` | A free text that groups resources, usually a URN such as `urn:inventory-api:resources:crate` |
| `uris` | The paths the resource stands for. A policy enforcer matches a request path against them |
| `icon_uri` | The address of an icon for user interfaces |
| `scopes` | The scopes (actions) that apply to the resource |
| `owner` | The user or client that owns the resource. A resource created in the Admin Console is owned by the resource server |
| `ownerManagedAccess` | `true` lets the owner share the resource with other users |
| `attributes` | Free key and value pairs that policies can read |

Only `name` is required. Every other field narrows what the resource means.

## Create a resource with the fields

The commands below need these helpers. Paste them once in each new terminal. `authz_id` returns the id of a scope, resource or policy by name. The field name for a resource id is `_id`, for the others it is `id`:

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
```

Create the resource `crate-1`. Scopes in a resource are listed by name, as objects:

```sh
kcadm create "$AUTHZ/resource" -r inventory \
  -s name=crate-1 -s displayName="Crate 1" \
  -s type=urn:inventory-api:resources:crate \
  -s 'uris=["/crates/1"]' \
  -s 'scopes=[{"name":"view"},{"name":"edit"}]' \
  -s 'attributes={"warehouse":["north"]}'
```

The command prints the id of the new resource. Read the resource back:

```sh
CRATE_ID=$(authz_id resource crate-1)
kcadm get "$AUTHZ/resource/$CRATE_ID" -r inventory
```

The answer lists every field from the table. The scopes show their ids and names, and `attributes` holds the value as a list, because an attribute can have several values. The field `owner` shows the resource server itself, because you created the resource through the Admin REST API and not as a user.

## Change one field

An update with `kcadm.sh` reads the resource, changes the fields you give and sends the whole object back. Change the display name:

```sh
kcadm update "$AUTHZ/resource/$CRATE_ID" -r inventory -s displayName="Crate number one"
kcadm get "$AUTHZ/resource/$CRATE_ID" -r inventory --fields name,displayName,type
```

The name stays and the display name changes. A permission that names `crate-1` still works, because the name did not change. If you change the `name` or the `type`, every permission that depends on the old value stops matching. That is why the next part treats the type as part of the rule and not as a label.

You can now read every field of a resource and change one without breaking the rest. What a field means for a decision depends on the permission that finds the resource, and the first way to find resources is by their type.

## Common pitfalls

> [!WARNING]
> - **Changing `name` without checking permissions.** A permission and a decision request name the resource. A new name breaks both.
> - **Reading `attributes` as a string.** Each attribute holds a list of values.
> - **Sending scope objects with only an `id`.** Name each scope, or Keycloak 26.8.1 can store only the first one.
> - **Expecting `displayName` to be unique.** Only `name` is unique.
