# Find The Policy That Denies

A `DENY` on a permission is only the top of the story. A permission can use several policies, and one of them can be an aggregated policy that holds more policies. The permission is denied because one policy at the bottom says no. A fix at the wrong level, such as changing the permission, hides the real fault. This part follows a `DENY` down the tree until it reaches the policy that caused it.

## The tree behind a permission

The permission `delete-items` in the playground uses one policy, the aggregated policy `staff-managers`. An aggregated policy is a policy that combines other policies with its own decision strategy. This one holds two: the role policy `inventory-managers`, which grants users with the realm role `inventory-manager`, and the group policy `staff-only`, which grants members of the group `staff`. Its strategy is `UNANIMOUS`, so both must grant. The playground also has a user `dana`, who has the role `inventory-manager` and is not in the group `staff`.

The commands below need these helpers. Paste them once in each new terminal. `evaluate` fills the placeholders of a request file with ids and sends it to the evaluation tool, and `jq_tester` runs `jq` in the `tester` pod:

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

Evaluate it for `dana` and print the status:

```sh
evaluate dana evaluate-delete.json | jq_tester '.status'
```

The answer is `DENY`, although `dana` is a manager. The status alone does not say why. Print the permission and the policies it uses, two levels deep:

```sh
evaluate dana evaluate-delete.json | jq_tester '[.results[0].policies[] | {permission: .policy.name, status, uses: [.associatedPolicies[]? | {policy: .policy.name, status, inner: [.associatedPolicies[]? | {policy: .policy.name, status}]}]}]'
```

The permission `delete-items` is `DENY`. It uses `staff-managers`, which is `DENY`. Inside `staff-managers`, the policy `inventory-managers` is `PERMIT` and the policy `staff-only` is `DENY`. The lowest `DENY` is the cause: `dana` is not in the group `staff`. The aggregated policy has the strategy `UNANIMOUS`, so one `DENY` is enough to deny the whole tree.

## Compare with a user who is granted

A second answer shows what a granted tree looks like. Print the same view for `alice`, who has the role and is in the group:

```sh
evaluate alice evaluate-delete.json | jq_tester '[.results[0].policies[] | {permission: .policy.name, status, uses: [.associatedPolicies[]? | {policy: .policy.name, status, inner: [.associatedPolicies[]? | {policy: .policy.name, status}]}]}]'
```

Every level is `PERMIT` for `alice`. Compare the two trees: the only difference is the line for `staff-only`. A `diff` of two evaluations is a fast way to find the policy that matters.

## Fix the cause, then prove it

The fault is the missing group membership, not the permission and not the policy. If the business rule is "managers in `staff` may delete", then the rule is correct and `dana` is missing from the group. Changing the permission to skip `staff-only` would open the delete scope for every manager outside the group. Put `dana` into the group and evaluate again:

```sh
kcadm update "users/$(user_uuid dana)/groups/$(kcadm get groups -r inventory -q search=staff -q exact=true --fields id --format csv --noquotes | head -n 1)" \
  -r inventory -s realm=inventory -s userId="$(user_uuid dana)" -n
evaluate dana evaluate-delete.json | jq_tester '.status'
```

The status is now `PERMIT`. Remove `dana` from the group again if you want to repeat the exercise. A real decision request for `dana` would now return `200` too, because the evaluation tool and the decision request use the same policies.

You can now follow a denial from the permission to the policy at the bottom of the tree, and name the one fact that caused it. The fix belongs where the fact is wrong. The next part uses the same tool for a different job: asking questions about users and facts that do not exist yet.

## Common pitfalls

> [!WARNING]
> - **Stopping at the permission.** The permission is denied because a policy below it said no. Read down to the lowest `DENY`.
> - **Fixing the permission instead of the cause.** Removing a policy from a permission opens access for everyone the policy used to stop.
> - **Reading a `NEGATIVE` policy wrongly.** A policy with logic `NEGATIVE` turns its own result around, so a `PERMIT` can mean the condition did not hold. Check the logic of the policy.
> - **Forgetting the decision strategy of the aggregated policy.** With `AFFIRMATIVE`, one `PERMIT` inside the tree is enough, and the tree reads differently.

## Your mission: Find The Policy That Denies With The Evaluation Tool

You can now trace a denial through a tree of policies and name the policy that causes it. The graded lab gives you a cluster where a manager is denied the delete scope. You use the evaluation tool to find the policy and fix the cause without changing the model.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-091-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-091-lab-020-02
astrona start ats-091-playground-020-02
```
