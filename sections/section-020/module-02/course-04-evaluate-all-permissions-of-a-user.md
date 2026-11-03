# Evaluate All Permissions Of A User

An administrator asked about a user rarely wants one answer. The question is "what can this person do?" The evaluation tool answers it when you ask for entitlements: it evaluates every resource and scope of the resource server for one user in a single call. This part asks that question, then asks the same question with a real request, and compares the two answers to confirm that the tool and the live system agree.

## Ask for the entitlements

The field `entitlements` in the request body switches the tool to this mode. When it is `true`, you give the user and the client, and you do not list resources. Keycloak returns the permissions the user holds, as the requesting party token (RPT) would carry them. The RPT is an access token that lists the granted resources and scopes in its `authorization.permissions` claim.

The commands below need these helpers. Paste them once in each new terminal:

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
evaluate() {   # evaluate USER FILE -> the JSON answer of the evaluation tool
  sed -e "s/<USER_ID>/$(user_uuid "$1")/" -e "s/<CLIENT_ID>/$CLIENT_ID/" "$2" |
    kcadm create "$AUTHZ/policy/evaluate" -r inventory -f - -o
}
jq_tester() { kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"; }
user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=$1 -d password=$1-password | jq -r .access_token"
}
```

The token request uses the password grant, which is only for terminal testing; a real application uses the authorization code flow. Save this as `evaluate-entitlements.json`:

```json
{
  "userId": "<USER_ID>",
  "clientId": "<CLIENT_ID>",
  "entitlements": true
}
```

Evaluate it for `alice` and print the permissions in the answer:

```sh
evaluate alice evaluate-entitlements.json | jq_tester 'keys'
evaluate alice evaluate-entitlements.json | jq_tester '.rpt.authorization.permissions'
```

The first command shows the fields of your answer, so you can find the permissions if they sit under another name. The second prints one entry per resource with the scopes `alice` holds, here `view`, `edit` and `delete` on `items`. Run it for `bob` and the entry shows only `view`.

## Ask the live system the same question

A real request can ask for the same list. Send a `uma-ticket` request with `response_mode=permissions` and `audience=inventory-api`, and the user's own token:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -H "Authorization: Bearer $(user_token bob)" \
  -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
  -d audience=inventory-api -d response_mode=permissions \
  -d response_include_resource_name=true | jq_tester '.'
```

The answer is a list with the resource name `items` and the scope `view`, which matches the evaluation for `bob`. Two ways of asking return the same facts, because they run the same policies. The difference is who asks. The evaluation tool needs the administrator and a user id. The live request needs the token of the user and works for the user only.

## When the two answers differ

If the evaluation grants and the live request denies, the policies are not the cause. Check three things in this order. First, the `audience`: a request for another client reads another resource server. Second, the token: an expired token or a token of another realm fails before any policy runs. Third, the client: a client policy can give a different answer for `inventory-cli` than for the client you chose in the evaluation.

If the live request grants and the evaluation denies, the likeliest cause is the request file: a wrong user id or a client id that is not the one the application uses. Evaluate again with the ids of the real user and client.

You can now list everything a user may do, and you can check the evaluation tool against a live request. The two views agree when they get the same inputs, and the cases where they differ point to the input, not the model. That closes the loop of debugging a decision: ask for the result, find the policy, test the change with a what-if question, and confirm with a live request.

## Common pitfalls

> [!WARNING]
> - **Reading entitlements as a promise.** The list shows what the policies grant now. A time policy or a role change can change it later.
> - **Comparing results for different clients.** A client policy can split the answers. Use the same client in both requests.
> - **Giving resources and `entitlements: true` together.** Entitlements mode returns the full list. Leave the resources out.
> - **Sharing the RPT output.** It shows the permissions of a user. Treat it like any access token content.
