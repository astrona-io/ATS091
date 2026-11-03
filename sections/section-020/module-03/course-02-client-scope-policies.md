# Client Scope Policies

A client policy trusts a whole application. Sometimes an application should get a power only when a request asks for it. A client scope is the OAuth 2.0 way to do that: the client asks for a scope when it requests a token, and the token then carries it. A client scope policy lets a permission depend on that scope. The same client can be granted for one request and denied for another.

## What a client scope policy checks

A **client scope** is a named set of protocol settings and permissions in Keycloak. A client has **default** scopes, which every token gets, and **optional** scopes, which a token gets only when the request names them in the `scope` parameter. A **client scope policy** grants a request when the token carries the client scopes the policy lists. Each entry has the flag `required`; when it is `true`, the scope must be present.

The commands below need these helpers. Paste them once in each new terminal. `decision_via` takes an optional fourth word, the scopes to request:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=clients-demo
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
user_token_via() {   # user_token_via CLIENT USER [SCOPES] -> an access token
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=$1 -d scope='openid $3' \
      -d username=$2 -d password=$2-password | jq -r .access_token"
}
decision_via() {   # decision_via CLIENT USER RESOURCE#SCOPE [SCOPES] -> 200 or 403
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token_via "$1" "$2" "$4")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$3" -d response_mode=decision
}
```

The token request in `user_token_via` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. The client scope `inventory-write` exists and `inventory-cli` has it as an optional scope. Create the resource `ledger` with the scope `post`:

```sh
kcadm create "$AUTHZ/resource" -r inventory -s name=ledger -s 'scopes=[{"name":"post"}]'
```

## Create the policy and the permission

The policy lists the client scope by its internal id:

```sh
SCOPE_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | grep ',inventory-write$' | cut -d, -f1)
kcadm create "$AUTHZ/policy/client-scope" -r inventory \
  -s name=write-scope-only -s logic=POSITIVE \
  -s "clientScopes=[{\"id\":\"$SCOPE_ID\",\"required\":true}]"
kcadm create "$AUTHZ/permission/scope" -r inventory \
  -s name=post-ledger -s type=scope -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource ledger)\"]" \
  -s "scopes=[\"$(authz_id scope post)\"]" \
  -s "policies=[\"$(authz_id policy write-scope-only)\"]"
```

## Ask with and without the scope

Request a token twice from the same client for the same user, once without and once with the optional scope:

```sh
echo "without scope $(decision_via inventory-cli alice ledger#post)"
echo "with scope    $(decision_via inventory-cli alice ledger#post inventory-write)"
```

The expected answers are `403` and `200`. The user, the client and the roles are the same in both requests. The only difference is the scope in the token. If both answers are `200`, check the scope claim of the token without the scope; if the scope is there, the client has it as a default scope and not as an optional scope.

## Choose the right policy

Use a role policy when the rule is about the person's job. Use a client policy when the rule is about which application may ask. Use a client scope policy when the rule is about what the application asked for in this request, which suits powers a user consents to and a client requests only when needed. An aggregated policy combines them, for example "a manager, and from the back office client".

You can now build a permission that depends on the scopes in a token and test it with and without the scope. You also have three kinds of fact to choose from when you write a rule: the person, the application and the request.

## Common pitfalls

> [!WARNING]
> - **Assigning the scope as a default scope.** Every token then carries it, and the policy always grants.
> - **Using the scope name in the policy.** The policy takes the internal id of the client scope.
> - **Forgetting `required`.** With `required` set to `false`, the scope is not needed for the policy to grant.
> - **Mixing up the two kinds of scope.** A client scope in the token is not the same as a scope of the resource, like `post`.
