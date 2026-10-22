# Role, User, Group, Client And Regex Policies

Most access rules are about who is asking. Sometimes "who" means a role, but often it means a group, one specific account, the application that sends the request, or an attribute such as the email address. Keycloak has a policy type for each of these. This part creates one of each and watches what each does to a decision, then turns one around with negative logic.

## A permission to experiment on

To see a policy's effect without breaking the inventory rules, this part adds a fourth scope, `audit`, to the resource `items`, protected by its own permission, `audit-items`. Each experiment swaps the policy that `audit-items` uses and asks Keycloak again.

The helpers are the same as everywhere in this module. `use_policy` replaces the policies of `audit-items` with the one you name. The token request inside `decision` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=policies-demo
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
use_policy() {
  kcadm update $AUTHZ/permission/scope/$(authz_id policy audit-items) -r inventory \
    -s "policies=[\"$(authz_id policy "$1")\"]"
  echo "alice $(decision alice items#audit) bob $(decision bob items#audit)"
}
```

Now create the scope, add it to `items`, and protect it with the role policy `inventory-viewers`, which both users pass:

```sh
kcadm create $AUTHZ/scope -r inventory -s name=audit
ITEMS_ID=$(authz_id resource items)
kcadm update $AUTHZ/resource/$ITEMS_ID -r inventory \
  -s "scopes=[{\"id\":\"$(authz_id scope view)\"},{\"id\":\"$(authz_id scope edit)\"},{\"id\":\"$(authz_id scope delete)\"},{\"id\":\"$(authz_id scope audit)\"}]"
kcadm create $AUTHZ/permission/scope -r inventory -s name=audit-items \
  -s "resources=[\"$ITEMS_ID\"]" -s "scopes=[\"$(authz_id scope audit)\"]" \
  -s "policies=[\"$(authz_id policy inventory-viewers)\"]"
echo "alice $(decision alice items#audit) bob $(decision bob items#audit)"
```

Both users get `200`. That is the role policy at work: it reads the user's realm roles, and both hold `inventory-viewer`.

## User and group policies

A **user policy** grants to the users it lists, by user id. It is the most direct rule and the hardest to maintain, because every new person needs an edit. A **group policy** grants to members of the groups it lists, by group id. With `extendChildren`, members of subgroups count too. Create one of each and swap them in:

```sh
BOB_ID=$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes)
STAFF_ID=$(kcadm get groups -r inventory -q search=staff -q exact=true --fields id --format csv --noquotes | head -n 1)
kcadm create $AUTHZ/policy/user -r inventory -s name=only-bob -s "users=[\"$BOB_ID\"]"
kcadm create $AUTHZ/policy/group -r inventory -s name=staff-members \
  -s "groups=[{\"id\":\"$STAFF_ID\",\"extendChildren\":false}]"
use_policy only-bob
use_policy staff-members
```

With `only-bob`, `alice` gets `403` and `bob` gets `200`. With `staff-members`, it is the other way round, because only `alice` is in `staff`. When a group policy has no **Groups Claim** set, Keycloak checks the user's group memberships itself, so the token does not need to carry them.

## Client and regex policies

A **client policy** grants when the request comes from one of the clients it lists. The client is the one the user's token was issued to, here `inventory-cli`. A **regex policy** reads one claim of the user's identity, named in **Target Claim**, and grants when its value matches the regular expression in **Regex Pattern**:

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes)
kcadm create $AUTHZ/policy/client -r inventory -s name=from-inventory-cli -s "clients=[\"$CLI_ID\"]"
kcadm create $AUTHZ/policy/regex -r inventory -s name=company-email \
  -s targetClaim=email -s 'pattern=^.+@example\.com$'
use_policy from-inventory-cli
use_policy company-email
```

Both users get `200` both times. Their tokens come from `inventory-cli`, and both email addresses end in `@example.com`. A regex policy is the simplest form of attribute-based access control: the rule depends on a value of the user, not on a role someone assigned.

## Negative logic

Every policy has a **logic**. `POSITIVE`, the default, keeps the result. `NEGATIVE` turns a grant into a deny and a deny into a grant. Set `staff-members` to `NEGATIVE` and use it again:

```sh
kcadm update $AUTHZ/policy/group/$(authz_id policy staff-members) -r inventory -s logic=NEGATIVE
use_policy staff-members
kcadm update $AUTHZ/policy/group/$(authz_id policy staff-members) -r inventory -s logic=POSITIVE
```

Now `alice` gets `403` and `bob` gets `200`: the policy grants to everyone who is **not** in `staff`. A negative policy is useful to exclude a group, but it grants to every user who fails the original check, including users nobody thought about. The last command puts the logic back.

You now know five policy types that look at who is asking: role, user, group, client and regex. Each reads one input, and negative logic turns its answer around. The open question is how to express rules that need two conditions at once, and rules that depend on when the request arrives.

## Common pitfalls

> [!WARNING]
> - **Using user policies for rules about kinds of people.** Every new person needs an edit to the policy. Use a role or a group instead.
> - **Writing a regex without anchors.** `example\.com` also matches `alice@example.com.attacker.org`. Anchor the pattern with `^` and `$`.
> - **Using negative logic to "exclude" a group.** The policy then grants to everyone outside the group, including users with no roles at all. Combine it with another policy that must also grant.
> - **Expecting a client policy to check the resource server.** It checks the client the user's token was issued to, not `inventory-api`.
