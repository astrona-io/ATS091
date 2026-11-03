# The Admin Console And The Admin REST API

Teams often build a model once in the Admin Console and then need to read, check and repeat it with scripts. The Admin Console does not have a private interface. Every tab on the Authorization page of a client calls the Admin REST API, which is the interface `kcadm.sh` uses. This part maps each tab to its call, and then uses three calls that the Console shows as links between objects: which permissions use a policy, which policies a permission uses, and which resources a permission protects.

## Each tab is one call

When you open the client `inventory-api` in the Admin Console, the Authorization tab has sub-tabs for settings, resources, scopes, policies, permissions, evaluate and export. Each one corresponds to a path under `clients/<id>/authz/resource-server` in the Admin REST API.

| Admin Console | Admin REST API path |
| --- | --- |
| Settings | `.` (the resource server itself) |
| Resources | `resource` |
| Authorization scopes | `scope` |
| Policies | `policy` |
| Permissions | `permission` |
| Evaluate | `policy/evaluate` |
| Export | `settings` |
| Import (when you create the settings) | `import` |

The list under `policy` includes permissions, because Keycloak stores a permission as a special kind of policy. The path `permission` lists only the permissions. `kcadm.sh` sends `GET`, `POST`, `PUT` and `DELETE` requests to these paths, and it signs in with the same administrator you use in the Console.

## List every object

Define the helpers, then list the four kinds of object. The option `--fields` keeps the answer to the fields you need:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=settings-demo
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
```

```sh
kcadm get $AUTHZ/resource -r inventory --fields name,type,uris
kcadm get $AUTHZ/scope -r inventory --fields name
kcadm get $AUTHZ/policy -r inventory --fields name,type,logic
kcadm get $AUTHZ/permission -r inventory --fields name,type
```

The resource list shows `items` with its type and URIs. The scope list shows the scopes of the resource server. The policy list shows the two role policies and the three scope permissions, whose type is `scope`. The permission list shows only the three permissions. If you also see objects named "Default Resource", "Default Policy" or "Default Permission", Keycloak created them when it switched authorization on. They protect a default resource type and do not affect the inventory decisions.

## Follow the links between objects

An object refers to other objects by id, so a list alone does not show how they connect. Three sub-paths answer the questions people ask in the Console.

To see which permissions use a policy, ask for its dependent policies. This is the list you need before you delete or change a policy:

```sh
kcadm get $AUTHZ/policy/$(authz_id policy inventory-managers)/dependentPolicies -r inventory --fields name
```

The answer lists `edit-items` and `delete-items`. Changing the policy `inventory-managers` changes both permissions.

To see which policies a permission uses, ask for its associated policies:

```sh
kcadm get $AUTHZ/policy/$(authz_id policy delete-items)/associatedPolicies -r inventory --fields name
```

The answer lists `inventory-managers`. To see what a permission protects, ask for its resources and its scopes:

```sh
kcadm get $AUTHZ/policy/$(authz_id policy delete-items)/resources -r inventory --fields name
kcadm get $AUTHZ/policy/$(authz_id policy delete-items)/scopes -r inventory --fields name
```

The permission `delete-items` protects the resource `items` and the scope `delete`. These four calls give the same links as the Console's detail pages for a policy and a permission.

## Read one object in full

A list with `--fields` shows only the fields you choose. To see everything about one object, get it by id. A type-specific path returns the settings of that type, for example the roles of a role policy:

```sh
kcadm get $AUTHZ/policy/role/$(authz_id policy inventory-managers) -r inventory
```

The answer includes the name, `logic`, `decisionStrategy` and the list of roles with their ids and the `required` flag. The generic path `policy/<id>` returns the common fields only. For a scope permission, use `permission/scope/<id>` to see its resources, scopes and policies together.

You can now find every object of a resource server and the links between them with plain calls. The Console and your scripts agree, because they use the same interface. The next question is how to get the whole model out as one file, which is what a team needs to review it, store it in version control or copy it.

## Common pitfalls

> [!WARNING]
> - **Changing a policy without checking its dependent policies.** One policy can protect several permissions. Ask for `dependentPolicies` first.
> - **Reading the `policy` list as "policies only".** It also lists permissions. Use `permission` for permissions only.
> - **Using a name where an id is needed.** Paths and references take ids. Look the id up by name with the `search` path.
> - **Assuming the Console has a feature the API lacks.** The Console only calls the API. A task you can click is a task you can script.
