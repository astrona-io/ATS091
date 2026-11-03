# Ask What-If Questions

An administrator often needs an answer before a change, not after it. Would a new hire with these roles be able to edit items? Would a request from another client be granted? A real decision request cannot answer these questions, because it needs a real user with a real token. The evaluation tool needs only ids, so it can evaluate a user with roles the user does not have. This part asks what-if questions about roles, clients and context attributes.

## Evaluate with other roles

The field `roleIds` in the request body lists realm role ids. When it is present, Keycloak evaluates the user with these roles in addition to the facts it already knows. The user stays the same and nothing in the realm changes. This is how you test a role policy before you assign the role to anybody.

The commands below need these helpers. Paste them once in each new terminal. `role_uuid` returns the id of a realm role:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=evaluate-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
AUTHZ="clients/$CLIENT_ID/authz/resource-server"
user_uuid() { kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes; }
role_uuid() { kcadm get "roles/$1" -r inventory --fields id --format csv --noquotes; }
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
evaluate() {   # evaluate USER FILE -> the JSON answer of the evaluation tool
  sed -e "s/<USER_ID>/$(user_uuid "$1")/" -e "s/<CLIENT_ID>/$CLIENT_ID/" \
      -e "s/<ITEMS_ID>/$(authz_id resource items)/" -e "s/<MANAGER_ROLE_ID>/$(role_uuid inventory-manager)/" "$2" |
    kcadm create "$AUTHZ/policy/evaluate" -r inventory -f - -o
}
jq_tester() { kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"; }
```

Save this as `evaluate-edit-as-manager.json`. It is the same question as before, with the manager role added:

```json
{
  "userId": "<USER_ID>",
  "clientId": "<CLIENT_ID>",
  "roleIds": [ "<MANAGER_ROLE_ID>" ],
  "resources": [
    {
      "_id": "<ITEMS_ID>",
      "scopes": [ { "name": "edit" } ]
    }
  ]
}
```

Evaluate it for `bob`, who is only a viewer, and then check that `bob` really has no new role:

```sh
evaluate bob evaluate-edit-as-manager.json | jq_tester '.status'
kcadm get "users/$(user_uuid bob)/role-mappings/realm" -r inventory --fields name
```

The status is `PERMIT`, and the role list of `bob` still shows only `inventory-viewer`. You learned that the role `inventory-manager` is enough to grant `edit`, and you changed nothing. Use the same request to test a new role policy before you assign the role.

## Evaluate for another client

The field `clientId` names the client that makes the request. A client policy can allow or deny by client, so the same user can get two different results from two clients. In the playground, the model has no client policy, so every client gets the same answer. The field still matters in a real system: when you evaluate a rule such as "only the `inventory-cli` client may delete", you set the field to the id of that client and again to the id of another one and compare the two results.

## Evaluate with context attributes

Some policies read facts that come from the request and not from the user. A time policy reads the clock. A JavaScript policy can read attributes such as the IP address of the caller. The request body can carry such facts in the `context` object, as `attributes`. The next request pretends that the call happens on a fixed date and time:

```json
{
  "userId": "<USER_ID>",
  "clientId": "<CLIENT_ID>",
  "context": {
    "attributes": {
      "kc.time.date_time": "2026-11-03 03:00:00"
    }
  },
  "resources": [
    {
      "_id": "<ITEMS_ID>",
      "scopes": [ { "name": "delete" } ]
    }
  ]
}
```

The attribute `kc.time.date_time` is the time that a time policy reads. In a realm with a time policy that allows only business hours, this request shows what the policy decides at three in the morning without anybody waiting for the night. The permissions of the playground have no time policy, so this request gives the same answer as one without a `context`. Keep the pattern: the tool lets you move the clock and the roles, and keeps the realm as it is.

You can now test a change before you make it, with other roles, another client or another time. The tool answers about one resource and scope at a time, which is slow for a user who holds many permissions. The last part asks for all permissions of a user at once and checks the tool against a real request.

## Common pitfalls

> [!WARNING]
> - **Reading a what-if result as a fact about the user.** `roleIds` adds roles for this one evaluation only. The user does not have them.
> - **Using a role name in `roleIds`.** The field takes role ids. Get them with `role_uuid`.
> - **Expecting `context` to change a policy that does not read it.** Only policies that use an attribute are affected by it.
> - **Testing a time policy by waiting.** Move the clock with the context attribute instead, and run the check in a second.
