# Overview: Debug Decisions With The Evaluation Tool (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates the realm `inventory` and builds a model in which the delete scope needs two things at once. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`evaluate-demo`**. The `master` realm administrator is `admin` with the password `admin`; these are lab-only credentials.
- The realm `inventory` with `alice` (roles `inventory-viewer` and `inventory-manager`, group `staff`), `bob` (role `inventory-viewer`) and `dana` (roles `inventory-viewer` and `inventory-manager`, no group). Passwords are `alice-password`, `bob-password` and `dana-password`.
- The resource server **`inventory-api`** with the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions. The permission `delete-items` uses the aggregated policy `staff-managers`, which holds the role policy `inventory-managers` and the group policy `staff-only` with the strategy `UNANIMOUS`.
- The pod **`tester`** with `curl` and `jq`.

## Helpers

Paste these once in each new terminal. `evaluate USER FILE` replaces `<USER_ID>`, `<CLIENT_ID>` and `<ITEMS_ID>` in a request file and sends it to the evaluation tool. `jq_tester` runs `jq` in the `tester` pod.

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

## Practice tasks

- Evaluate `edit` and `delete` for `alice`, `bob` and `dana` and print the tree of policies for each answer.
- Change the strategy of `staff-managers` to `AFFIRMATIVE` and evaluate `dana` again. Change it back.
- Evaluate `bob` with the `inventory-manager` role id in `roleIds` and prove that his role mappings did not change.
- Ask for the entitlements of all three users and compare them with `response_mode=permissions` requests.
