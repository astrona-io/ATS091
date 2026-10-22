# Decision Strategies And The Enforcement Mode

Real permissions rarely use one policy. A delete might need "is a manager" and also "is a member of staff". Sometimes the opposite is true: a request matches no permission at all, because a new scope was added and nobody wrote a rule for it yet. This part shows how Keycloak combines several policy results, and what it does when nothing matches. Both settings decide whether a mistake in the model fails closed or fails open.

## Three decision strategies

A decision strategy says how the results of several policies combine into one result for a permission. Keycloak has three:

| Strategy | The permission grants when |
| --- | --- |
| `UNANIMOUS` (the default) | Every policy grants |
| `AFFIRMATIVE` | At least one policy grants |
| `CONSENSUS` | More policies grant than deny; a tie denies |

The resource server has a decision strategy too. It combines the results of several **permissions** that match the same request, with the same three rules. With the default `UNANIMOUS`, every matching permission must grant.

The commands below need the same helpers as before, defined again here so this page stands on its own. They expect the model built earlier in this module: the resource `items` with the scopes `view`, `edit` and `delete`, the role policies `inventory-viewers` and `inventory-managers`, and the permissions `view-items`, `edit-items` and `delete-items`.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=model-demo
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
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}
```

Give `delete-items` a second policy, `inventory-viewers`, and keep `UNANIMOUS`. Both policies must now grant:

```sh
DELETE_ITEMS_ID=$(authz_id policy delete-items)
kcadm update $AUTHZ/permission/scope/$DELETE_ITEMS_ID -r inventory -s decisionStrategy=UNANIMOUS \
  -s "policies=[\"$(authz_id policy inventory-managers)\",\"$(authz_id policy inventory-viewers)\"]"
echo "alice $(decision alice items#delete) bob $(decision bob items#delete)"
```

`alice` still gets `200`, because she has both roles. `bob` gets `403`: the viewer policy grants, but the manager policy denies, and `UNANIMOUS` needs both. Now change only the strategy to `AFFIRMATIVE`:

```sh
kcadm update $AUTHZ/permission/scope/$DELETE_ITEMS_ID -r inventory -s decisionStrategy=AFFIRMATIVE
echo "alice $(decision alice items#delete) bob $(decision bob items#delete)"
```

Now `bob` gets `200`. One granting policy is enough, and every viewer passes the viewer policy. That one word turned a rule for managers into a rule for everyone who can view. Put the permission back the way it was:

```sh
kcadm update $AUTHZ/permission/scope/$DELETE_ITEMS_ID -r inventory -s decisionStrategy=UNANIMOUS \
  -s "policies=[\"$(authz_id policy inventory-managers)\"]"
```

## What happens when no permission matches

The policy enforcement mode of the resource server says what Keycloak does when a request matches no permission. It also has three values:

| Mode | A request that no permission covers |
| --- | --- |
| `ENFORCING` (the default) | Is denied |
| `PERMISSIVE` | Is granted |
| `DISABLED` | Every request is granted; Keycloak does not evaluate policies at all |

To see the difference, add a fourth scope, `export`, to `items`, but write no permission for it. Then ask for it as `alice`, who may do everything else:

```sh
kcadm create $AUTHZ/scope -r inventory -s name=export
ITEMS_ID=$(authz_id resource items)
kcadm update $AUTHZ/resource/$ITEMS_ID -r inventory \
  -s "scopes=[{\"id\":\"$(authz_id scope view)\"},{\"id\":\"$(authz_id scope edit)\"},{\"id\":\"$(authz_id scope delete)\"},{\"id\":\"$(authz_id scope export)\"}]"
echo "alice export $(decision alice items#export)"
```

`alice` gets `403`. In `ENFORCING` mode, a scope with no permission is closed to everyone, even to a user who holds every role. Now switch the mode to `PERMISSIVE` and ask again, for `alice` and for `bob`:

```sh
kcadm update $AUTHZ -r inventory -s policyEnforcementMode=PERMISSIVE
echo "alice export $(decision alice items#export) bob export $(decision bob items#export) bob delete $(decision bob items#delete)"
```

Both users now get `200` for `export`, because no permission covers it. `bob` still gets `403` for `delete`, because a permission covers that scope and it denies him. `PERMISSIVE` only opens what nobody wrote a rule for, which is exactly the part of a model that is easiest to forget. Switch back to `ENFORCING`:

```sh
kcadm update $AUTHZ -r inventory -s policyEnforcementMode=ENFORCING
```

You can now predict a permission's result from its policies and its decision strategy, and a request's result when no permission matches. Together they decide whether a mistake in the model denies too much, which someone reports at once, or allows too much, which nobody reports. The question left for later is how to write richer rules than roles: groups, attributes, the time of day, and combinations of them.

## Common pitfalls

> [!WARNING]
> - **Adding a policy to a permission with `AFFIRMATIVE`.** Every extra policy becomes a new way in. With `UNANIMOUS` it becomes a new condition.
> - **Using `PERMISSIVE` to "fix" a denial.** It grants every request that no permission covers, including scopes you add later. Write the missing permission instead.
> - **Forgetting the resource server's own decision strategy.** When two permissions match the same scope, the resource server's strategy combines them, and with `UNANIMOUS` one denying permission is enough to deny.
> - **Expecting `DISABLED` to be a test mode for one resource.** It switches policy evaluation off for the whole resource server.
