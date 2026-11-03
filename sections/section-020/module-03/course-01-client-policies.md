# Client Policies

A person can reach the same API from several applications: a back office tool, a command line tool, a mobile app. The company may trust the person and still not trust every application. A role policy cannot express this, because the roles of the person are the same in all applications. A client policy can, because it looks at the client that sent the request.

## What a client policy checks

A **client policy** grants a request when the client behind it is in a list. The client is the OAuth 2.0 application that asked for the token. Keycloak writes its client ID in the claim `azp` (authorized party) of the access token. The user's token that you send in a decision request therefore carries the client where the user signed in.

The commands below need these helpers. Paste them once in each new terminal. `decision_via` gets a token for a user from a chosen client and asks for a decision:

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
client_uuid() { kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes; }
user_token_via() {   # user_token_via CLIENT USER -> an access token for USER from CLIENT
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=$1 \
      -d username=$2 -d password=$2-password | jq -r .access_token"
}
decision_via() {   # decision_via inventory-cli alice reports#export -> 200 or 403
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token_via "$1" "$2")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$3" -d response_mode=decision
}
```

The token request in `user_token_via` uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. Create the resource `reports` with the scope `export`:

```sh
kcadm create "$AUTHZ/resource" -r inventory -s name=reports -s 'scopes=[{"name":"export"}]'
```

## Create the client policy and the permission

The client policy takes the internal ids of the clients it allows. Allow only `reports-cli`:

```sh
kcadm create "$AUTHZ/policy/client" -r inventory \
  -s name=reports-cli-only -s logic=POSITIVE \
  -s "clients=[\"$(client_uuid reports-cli)\"]"
```

A policy protects nothing until a permission uses it. Create a scope permission for the scope `export`:

```sh
kcadm create "$AUTHZ/permission/scope" -r inventory \
  -s name=export-reports -s type=scope -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource reports)\"]" \
  -s "scopes=[\"$(authz_id scope export)\"]" \
  -s "policies=[\"$(authz_id policy reports-cli-only)\"]"
```

## One user, two clients

Ask for the same decision for `alice` from both clients:

```sh
echo "reports-cli   $(decision_via reports-cli alice reports#export)"
echo "inventory-cli $(decision_via inventory-cli alice reports#export)"
```

The first answer is `200` and the second is `403`. The person is the same and her roles are the same. Only the client differs, and the policy checks only the client. Print the claim `azp` of the token to see the value the policy compared:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c "echo '$(user_token_via inventory-cli alice)' | cut -d. -f2 | base64 -d 2>/dev/null | jq -r .azp"
```

You can now restrict a permission to chosen applications and prove it from two clients. A client policy is a blunt rule: the whole client is in or out. When an application should get a power only for the requests that ask for it, the next part uses the scopes that the client requests.

## Common pitfalls

> [!WARNING]
> - **Using a client name in `clients`.** The policy takes internal ids. Use `client_uuid`.
> - **Using a client policy as the only protection.** A client policy does not look at the person. Add a role or user policy in an aggregated policy if the person matters.
> - **Testing with one client only.** Always ask from an allowed client and from a client that must be denied.
> - **Treating a public client as secret.** Any user can start a public client. The policy tells which client sent the request, not whether the client is trustworthy.

## Your mission: Allow Only One Client To Export

You can now create a client policy and prove it from two clients. The graded lab gives you a cluster with a resource `invoices` that no permission protects yet. You create the client policy and the permission so that only the client `billing-cli` can export invoices.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-091-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-091-lab-020-03
astrona start ats-091-playground-020-03
```
