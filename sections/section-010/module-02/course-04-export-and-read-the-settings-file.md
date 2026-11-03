# Export And Read The Settings File

A model that exists only inside a running Keycloak is hard to review, hard to store and hard to repeat. Keycloak can write the whole model of a resource server into one JSON file. This part exports that file, then reads it with `jq` so you know where each object lives in it and how objects refer to each other.

## Export the settings

The export is a `GET` request to the path `settings` of the resource server. The answer is the **authorization settings file**: a JSON document with the resource server's settings, its resources, scopes and policies. Define the helpers, then save the file inside the `tester` pod, where `jq` is installed.

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
```

```sh
kcadm get $AUTHZ/settings -r inventory | kubectl -n "$NAMESPACE" exec -i deploy/tester -- sh -c 'cat > /tmp/inventory-api-settings.json'
```

The file is now at `/tmp/inventory-api-settings.json` in the `tester` pod. Define a helper that runs `jq` on it, so each question below is one short command:

```sh
settings_query() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- jq "$@" /tmp/inventory-api-settings.json
}
settings_query 'keys'
```

The keys include `policyEnforcementMode`, `decisionStrategy`, `allowRemoteResourceManagement`, `resources`, `policies` and `scopes`. The first three are the settings from the previous part. The other three hold the objects.

## Read the objects

Ask for the names of the resources and scopes:

```sh
settings_query '[.resources[].name]'
settings_query '[.scopes[].name]'
```

The first list includes `items`. The second includes `view`, `edit` and `delete`. A resource entry in the file also holds its `type`, its `uris` and its own list of scopes. Look at the resource `items` in full:

```sh
settings_query '.resources[] | select(.name == "items")'
```

Now list the policies with their type. Because Keycloak stores a permission as a policy, the same list holds the roles policies and the three permissions:

```sh
settings_query '[.policies[] | {name, type}]'
```

You see `inventory-viewers` and `inventory-managers` with the type `role`, and `view-items`, `edit-items` and `delete-items` with the type `scope`.

## How objects refer to each other in the file

In the live system, one object refers to another by id. In the file, they refer to each other by name. The file has no ids that mean anything outside this one Keycloak, so it can be loaded into a different server. Look at the permission `delete-items`:

```sh
settings_query '.policies[] | select(.name == "delete-items") | .config'
```

The `config` object has the fields `resources`, `scopes` and `applyPolicies`. Each is a string that holds a JSON list of names: the resource `items`, the scope `delete` and the policy `inventory-managers`. Now look at the role policy:

```sh
settings_query '.policies[] | select(.name == "inventory-managers") | .config'
```

The `roles` field holds the role by name too. This is why the file travels well: the target realm needs a role with the same name, not the same id.

## What the file does not contain

The file holds the model of one resource server. It does not hold the users, the roles or the groups that policies refer to. It does not hold the client itself, its secret or its service account. A policy that names a role works in the target only when that role exists there. Check this before you load the file anywhere.

Because the file is plain text, you can store it in version control and compare two versions with a normal `diff`. A change to a policy then shows as a line in a review, with the same information the Admin Console shows in its pages.

You can now export a model and read any object in it. A file that you cannot load is only a report. The next part loads the file into a second resource server and proves that both servers decide the same way.

## Common pitfalls

> [!WARNING]
> - **Treating the file as a backup of the realm.** It holds the authorization model only. Users, roles, groups and clients are not in it.
> - **Looking for ids in the file.** Objects refer to each other by name inside `config`. Two objects with the same name in the same type confuse that link.
> - **Pasting the file into a public place.** It shows every rule of your API and the names of your roles.
> - **Reading the file with a tool that changes quotes.** The `config` values are strings that hold JSON. Edit them as strings.
