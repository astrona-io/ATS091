# Resource Server Settings

Every object in a resource server has its own settings, but the resource server itself has three settings that apply to all of them. They decide what happens when no permission matches a request, how the results of several permissions are combined, and whether the API may register its own resources. This part reads each setting, explains what it does, changes it in the playground, and puts it back.

## Read the three settings

The resource server is the client `inventory-api` with authorization switched on. Its settings live at the path `clients/<id>/authz/resource-server` of the Admin REST API. Define the helpers first, if your terminal does not have them yet.

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
```

Read the settings:

```sh
kcadm get $AUTHZ -r inventory --fields policyEnforcementMode,decisionStrategy,allowRemoteResourceManagement
```

The answer has the three fields. In the playground, `policyEnforcementMode` is `ENFORCING` and `decisionStrategy` is `UNANIMOUS`. Remote resource management is switched off.

## The policy enforcement mode

The **policy enforcement mode** decides what the policy decision point does when a request names a resource or a scope that no permission protects. `ENFORCING` denies the request. `PERMISSIVE` grants it. `DISABLED` grants everything and does not evaluate any policy at all. The safe value is `ENFORCING`, because a resource that someone forgot to protect stays closed.

The mode matters only for requests that match no permission. A request that matches a permission is always decided by that permission, in every mode except `DISABLED`.

To see the mode at work, create a scope that no permission protects and add it to the resource `items`. The helper `authz_id` looks up an id by name, because one object refers to another by id:

```sh
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
kcadm create $AUTHZ/scope -r inventory -s name=archive
kcadm update $AUTHZ/resource/$(authz_id resource items) -r inventory \
  -s "scopes=[{\"name\":\"view\"},{\"name\":\"edit\"},{\"name\":\"delete\"},{\"name\":\"archive\"}]"
echo "alice archive $(decision alice items#archive)"
```

The answer is `403`. No permission protects `archive`, and the mode is `ENFORCING`, so the request is denied. Switch the mode to `PERMISSIVE` and ask again:

```sh
kcadm update $AUTHZ -r inventory -s policyEnforcementMode=PERMISSIVE
echo "alice archive $(decision alice items#archive) bob archive $(decision bob items#archive)"
kcadm update $AUTHZ -r inventory -s policyEnforcementMode=ENFORCING
```

Both users now get `200`, even `bob`, because nothing protects the scope. The last command restores the safe mode. Never leave `PERMISSIVE` on for an API that holds data other people must not reach.

## The decision strategy of the resource server

A request can match more than one permission, for example a request for the whole resource `items` without a scope. The **decision strategy** of the resource server combines the results of those permissions. `UNANIMOUS` needs every permission to grant. `AFFIRMATIVE` needs one permission to grant. Keycloak also lets each permission set its own strategy for the policies it uses. The two levels are different: the strategy on a permission combines policies, and the strategy on the resource server combines permissions.

Read the strategy of one permission and compare it with the server:

```sh
kcadm get $AUTHZ/permission -r inventory --fields name,decisionStrategy
kcadm get $AUTHZ -r inventory --fields decisionStrategy
```

All three permissions use `UNANIMOUS`, and so does the server. A request for `items` without a scope is decided by `view-items`, `edit-items` and `delete-items` together. With `UNANIMOUS`, `bob` is denied because `edit-items` and `delete-items` deny him. With `AFFIRMATIVE`, `bob` is granted because `view-items` grants him. Check it by asking for the resource alone, then switch the strategy, ask again and restore it:

```sh
echo "bob items $(decision bob items)"
kcadm update $AUTHZ -r inventory -s decisionStrategy=AFFIRMATIVE
echo "bob items $(decision bob items)"
kcadm update $AUTHZ -r inventory -s decisionStrategy=UNANIMOUS
```

The first answer is `403` and the second is `200`. A single `AFFIRMATIVE` setting on the server would let an API that asks for a whole resource accept a user who may do only one of the actions, so keep `UNANIMOUS` unless you have a reason.

## Remote resource management

The third setting is **remote resource management**, the field `allowRemoteResourceManagement`. When it is `true`, the resource server may create, change and delete its own resources through the Protection API, using its own token. When it is `false`, resources can only be managed with the Admin Console or the Admin REST API.

Switch it on and read it back, then switch it off again:

```sh
kcadm update $AUTHZ -r inventory -s allowRemoteResourceManagement=true
kcadm get $AUTHZ -r inventory --fields allowRemoteResourceManagement
kcadm update $AUTHZ -r inventory -s allowRemoteResourceManagement=false
```

An API that registers a resource for every document a user creates needs this setting on. An API with a fixed list of resources does not need it, and leaving it off means a stolen token of the API cannot add resources.

You now know where the three settings live, what each one changes, and how to prove the change with a decision. The settings are part of the model, and the model has many more objects. The next part shows where every one of them lives in the Admin Console and in the Admin REST API.

## Common pitfalls

> [!WARNING]
> - **Using `PERMISSIVE` to "make a test pass".** It grants every request that no permission protects. A forgotten scope then stays open.
> - **Confusing the two decision strategies.** The strategy on a permission combines its policies. The strategy on the resource server combines permissions for a request that matches several.
> - **Setting `DISABLED` to find a problem.** In this mode Keycloak does not evaluate policies at all and grants everything, so it hides the fault instead of showing it.
> - **Turning on remote resource management without need.** It lets the resource server change its own resources. Switch it on only for an API that registers resources at run time.
