# Solution: Find The Policy That Denies With The Evaluation Tool

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the decisions of `dana`, `alice` and `bob`, that the model is unchanged, and that `dana` keeps her roles.

## Step 1: Define the helpers

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
evaluate() {
  sed -e "s/<USER_ID>/$(user_uuid "$1")/" -e "s/<CLIENT_ID>/$CLIENT_ID/" -e "s/<ITEMS_ID>/$(authz_id resource items)/" "$2" |
    kcadm create "$AUTHZ/policy/evaluate" -r inventory -f - -o
}
jq_tester() { kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq "$@"; }
```

## Step 2: Evaluate the request

Save this as `evaluate-delete.json`:

```json
{
  "userId": "<USER_ID>",
  "clientId": "<CLIENT_ID>",
  "resources": [
    {
      "_id": "<ITEMS_ID>",
      "scopes": [ { "name": "delete" } ]
    }
  ]
}
```

Print the tree of policies for `dana`:

```sh
evaluate dana evaluate-delete.json | jq_tester '[.results[0].policies[] | {permission: .policy.name, status, uses: [.associatedPolicies[]? | {policy: .policy.name, status, inner: [.associatedPolicies[]? | {policy: .policy.name, status}]}]}]'
```

The permission `delete-items` and the aggregated policy `staff-managers` are `DENY`. Inside it, `inventory-managers` is `PERMIT` and `staff-only` is `DENY`. The cause is the group policy: `dana` is not in the group `staff`.

## Step 3: Fix the cause

Add `dana` to the group. Do not touch the policies.

```sh
GROUP_ID=$(kcadm get groups -r inventory -q search=staff -q exact=true --fields id --format csv --noquotes | head -n 1)
kcadm update "users/$(user_uuid dana)/groups/$GROUP_ID" -r inventory \
  -s realm=inventory -s userId="$(user_uuid dana)" -s groupId="$GROUP_ID" -n
```

## Step 4: Prove it

```sh
evaluate dana evaluate-delete.json | jq_tester '.status'
evaluate bob evaluate-delete.json | jq_tester '.status'
```

`dana` gets `PERMIT` and `bob` gets `DENY`. A real decision request for `dana` returns `200` too.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove `staff-only` from `staff-managers` | `dana` is granted, and so is every manager outside the group; the check for the model fails |
| Set the strategy of `staff-managers` to `AFFIRMATIVE` | Same opening, and the check for the model fails |
| Set `PERMISSIVE` | `bob` is granted `delete` too |
