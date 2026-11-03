# Types And Resource-Type Permissions

An application that creates a new resource for every shelf, parcel or album cannot ask an administrator to add a permission each time. A permission for each resource does not scale, and a permission for a name cannot cover a name that does not exist yet. The `type` field solves this. A permission can name a type instead of a resource, and it then protects every resource of that type, now and later.

## Group resources with a type

The `type` of a resource is free text. The usual form is a URN (a Uniform Resource Name, a structured text identifier) such as `urn:inventory-api:resources:parcel`. Keycloak does not check the value. It only compares the text, so `urn:inventory-api:resources:parcel` and `urn:inventory-api:resources:parcels` are two different types.

The commands below need these helpers. Paste them once in each new terminal. `decision` asks Keycloak whether a user may use a resource, and it returns `200` for granted and `403` for denied:

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
decision() {   # decision alice parcel-1 -> 200 (granted) or 403 (denied)
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
```

The token request in `user_token` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. Create two resources of the type `parcel` and one resource with no type:

```sh
for name in parcel-1 parcel-2; do
  kcadm create "$AUTHZ/resource" -r inventory -s name=$name -s type=urn:inventory-api:resources:parcel
done
kcadm create "$AUTHZ/resource" -r inventory -s name=parcel-3
```

## Protect the type with one permission

A resource-based permission can use `resourceType` instead of a list of resources. Create it with the existing role policy `inventory-viewers`. The permission takes the id of the policy:

```sh
VIEWERS_ID=$(authz_id policy inventory-viewers)
kcadm create "$AUTHZ/permission/resource" -r inventory \
  -s name=view-parcels -s type=resource \
  -s resourceType=urn:inventory-api:resources:parcel \
  -s decisionStrategy=UNANIMOUS \
  -s "policies=[\"$VIEWERS_ID\"]"
```

Now ask for a decision for `bob`, who has the role `inventory-viewer`:

```sh
for name in parcel-1 parcel-2 parcel-3; do echo "bob $name $(decision bob $name)"; done
```

`bob` gets `200` for `parcel-1` and `parcel-2`, and `403` for `parcel-3`. The permission finds a resource by its type, and `parcel-3` has no type. The permission is fine. The resource is described badly.

## Fix the resource, not the permission

Give `parcel-3` the type and ask again:

```sh
PARCEL3_ID=$(authz_id resource parcel-3)
kcadm update "$AUTHZ/resource/$PARCEL3_ID" -r inventory -s type=urn:inventory-api:resources:parcel
decision bob parcel-3
```

The answer is now `200`. You made no new permission, and the next parcel the application registers with the right type is covered at once. This is the reason to protect types: the rule is written once and applies to every resource that fits.

You can now group resources by type and protect the group with one permission, and you can tell a missing type from a missing permission. A permission without scopes grants more than it seems to, and the next part shows how much.

## Common pitfalls

> [!WARNING]
> - **A type with a typing mistake.** `parcel` and `parcels` are different types. The permission matches the exact text.
> - **Adding a new permission for one resource that lacks a type.** Fix the type. A new permission for a name adds a rule that has to be kept.
> - **Expecting the type to be unique.** Many resources share one type. That is the purpose.
> - **Using the type of the resource server as a rule.** Keycloak does not read the text. The permission and the resource must carry the same text.

## Your mission: Fix A Resource That No Permission Covers

You can now find out why a permission misses a resource and fix the resource. The graded lab gives you a cluster where `bob` is denied one shelf that his colleagues can view. You find the cause and fix the resource without creating or changing a permission.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-091-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-091-lab-010-03
astrona start ats-091-playground-010-03
```
