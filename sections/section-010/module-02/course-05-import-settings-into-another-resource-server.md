# Import Settings Into Another Resource Server

Teams run the same API in more than one place: a test environment, a second region, a new version of the service. Each place needs the same authorization model. Building it by hand twice invites mistakes. This part loads the exported settings file into a second resource server, `inventory-api-v2`, and proves that both resource servers decide the same way.

## Look at the target first

`inventory-api-v2` is a confidential client in the same realm with authorization switched on. It has no model of its own. Define the helpers and list what it holds:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=settings-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
SOURCE_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
TARGET_ID=$(kcadm get clients -r inventory -q clientId=inventory-api-v2 --fields id --format csv --noquotes)
SOURCE="clients/$SOURCE_ID/authz/resource-server"
TARGET="clients/$TARGET_ID/authz/resource-server"
kcadm get $TARGET/resource -r inventory --fields name
kcadm get $TARGET/policy -r inventory --fields name,type
```

If the lists show objects named "Default Resource", "Default Policy" and "Default Permission", Keycloak created them when it switched authorization on. The exported file from `inventory-api` carries its own default objects when it has them, and two objects with the same name in one resource server clash. Delete the defaults of the target before you import. Delete the permission and the policy first, then the resource, because the permission uses both:

```sh
target_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$TARGET/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
for name in "Default Permission" "Default Policy"; do
  id=$(target_id policy "$name"); [ -n "$id" ] && kcadm delete "$TARGET/policy/$id" -r inventory
done
id=$(target_id resource "Default Resource"); [ -n "$id" ] && kcadm delete "$TARGET/resource/$id" -r inventory
```

The command skips an object that does not exist, so it is safe to run when the lists were empty.

## Import the file

The import is a `POST` request to the path `import` of the target, with the settings file as the body. `kcadm.sh` reads the body from standard input when you pass `-f -`. Export from the source and import into the target in one pipe:

```sh
kcadm get $SOURCE/settings -r inventory | kcadm create $TARGET/import -r inventory -f -
```

The import creates the scopes, the resources, the policies and the permissions of the file in the target, and it sets the three resource server settings from the file. Check the target with the same listing calls you used on the source:

```sh
kcadm get $TARGET -r inventory --fields policyEnforcementMode,decisionStrategy
kcadm get $TARGET/resource -r inventory --fields name,uris
kcadm get $TARGET/permission -r inventory --fields name,type
```

The target is in `ENFORCING` mode with the strategy `UNANIMOUS`, it has the resource `items` with its two URIs, and it has the three permissions. The role policies found the roles `inventory-viewer` and `inventory-manager` by name, because the file refers to roles by name and the realm has them.

## Prove the decisions match

A copy is only a copy when it decides the same way. Define the request helpers. They take the resource server as an extra argument, the `audience` of the request:

```sh
user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=$1 -d password=$1-password | jq -r .access_token"
}
decision() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token "$1")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience="${3:-inventory-api}" -d permission="$2" -d response_mode=decision
}
for server in inventory-api inventory-api-v2; do
  for user in alice bob; do for scope in view edit delete; do
    echo "$server $user $scope $(decision $user items#$scope $server)"
  done; done
done
```

The token request uses the password grant, which is only for terminal testing. `alice` gets `200` for all three scopes on both servers, and `bob` gets `200` for `view` and `403` for `edit` and `delete` on both servers. The Admin Console offers the same import on the Authorization tab when you open a resource server with no model.

You can now move a model between resource servers with two calls and prove that the copy is faithful. The model of `inventory-api` is unchanged, and `inventory-api-v2` is a second server that enforces the same rules. A change made later to one server does not reach the other, so a team repeats the export and import, or keeps the file in version control as the source of truth.

## Common pitfalls

> [!WARNING]
> - **Importing into a server that already has objects with the same names.** Delete the default objects first, or import into an empty server.
> - **Importing a file whose role policies name a role the target realm lacks.** The import cannot link the policy. Create the role first.
> - **Forgetting the `audience`.** A decision request for `inventory-api-v2` must name it in `audience`. Without it, the request goes to the wrong resource server.
> - **Expecting a later change to follow the copy.** The import copies the model once. It does not keep two servers in step.

## Your mission: Copy A Resource Server With Export And Import

You can now export the model of one resource server and load it into another. The graded lab gives you a fresh Keycloak with a finished `inventory-api` and an empty `inventory-api-v2`, and asks you to make the second one decide exactly like the first without touching the first.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-091-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-091-lab-010-02
astrona start ats-091-playground-010-02
```
