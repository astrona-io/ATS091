# Ask The Evaluation Tool For A Result

A decision request returns `200` or `403` and nothing else. A team that gets a wrong `403` has no way to see which policy said no. The evaluation tool closes this gap. It is an Admin REST API call that runs the policies of a resource server for a chosen user and resource, and returns the result of each permission and each policy. This part sends the first evaluation request and reads the fields of the answer.

## One request, one answer

The evaluation tool is the `POST` path `policy/evaluate` under the resource server, the same path the Evaluate tab of the Admin Console calls. The body is a JSON document with the user (`userId`), the client that makes the request (`clientId`) and the resources and scopes to evaluate. All three ids are Keycloak internal ids, not names. Keycloak runs the same evaluation it runs for a real request, so the result is the result a real request would get.

The first step defines the helpers. `evaluate` fills the placeholders of a request file and sends it. `jq_tester` runs `jq` in the `tester` pod, because the administrator machine may not have `jq`.

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
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
evaluate() {   # evaluate USER FILE -> the JSON answer of the evaluation tool
  sed -e "s/<USER_ID>/$(user_uuid "$1")/" -e "s/<CLIENT_ID>/$CLIENT_ID/" -e "s/<ITEMS_ID>/$(authz_id resource items)/" "$2" |
    kcadm create "$AUTHZ/policy/evaluate" -r inventory -f - -o
}
jq_tester() { kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"; }
```

Save this as `evaluate-edit.json`. It asks whether the user may use the scope `edit` of the resource `items`:

```json
{
  "userId": "<USER_ID>",
  "clientId": "<CLIENT_ID>",
  "resources": [
    {
      "_id": "<ITEMS_ID>",
      "scopes": [ { "name": "edit" } ]
    }
  ]
}
```

The file holds placeholders because the ids differ in every cluster. The `evaluate` helper replaces them. Evaluate for `alice`, who has the role `inventory-manager`, and for `bob`, who does not:

```sh
evaluate alice evaluate-edit.json | jq_tester '.status'
evaluate bob evaluate-edit.json | jq_tester '.status'
```

`alice` gets `PERMIT` and `bob` gets `DENY`. These are the same answers a decision request gives as `200` and `403`.

## Read the fields of the answer

The answer has more than the status. Print the names of its fields to see them in your own cluster, and then the part for the first resource:

```sh
evaluate bob evaluate-edit.json | jq_tester 'keys'
evaluate bob evaluate-edit.json | jq_tester '.results[0] | {resource: .resource.name, status, allowedScopes: [.allowedScopes[]?.name], scopes: [.scopes[]?.name]}'
```

The top level holds `results`, one entry per resource, and an overall `status`. Each entry in `results` names the `resource`, the scopes you asked for, the `allowedScopes` (the scopes that were granted) and a list of `policies`. For `bob` the list `allowedScopes` is empty. The field names above come from the documentation; if `jq` prints `null` for one of them, run `keys` on that level of your own answer and use the names it shows.

Every entry in `policies` is a permission that matched the request, with its own `status` and the policies it uses in `associatedPolicies`. List them for `bob`:

```sh
evaluate bob evaluate-edit.json | jq_tester '.results[0].policies[] | {permission: .policy.name, status}'
```

Only the permission `edit-items` matches, because the request asks for the scope `edit`. The permissions `view-items` and `delete-items` protect other scopes and do not run. The next part follows the `DENY` from the permission down to the policy that caused it.

## What the evaluation tool does not do

The tool evaluates policies for a user you name. It does not check a password, it does not read a token and it does not call the policy enforcement point of any API. It therefore proves what the model decides, not what an API does with the decision. A wrong answer from a real API with a correct evaluation means the fault is in the API, in the token the client sends or in the `audience` of the request.

You can now ask Keycloak for the result of one permission and read the status, the allowed scopes and the matching permissions. The result names the permission but not yet the reason. The reason is one level lower, in the policies that a permission uses.

## Common pitfalls

> [!WARNING]
> - **Sending names where ids are needed.** `userId`, `clientId` and the resource `_id` are internal ids. A name returns an error or an empty result.
> - **Reading `PERMIT` as proof that the API works.** The tool evaluates the model only. Test the API with a real request too.
> - **Forgetting the scopes.** A resource without `scopes` in the request asks for the resource as a whole, and the answer can differ from the answer for one scope.
> - **Using the resource `id` field from a search.** Resources use `_id`. Use `authz_id resource items`, which asks for it.
