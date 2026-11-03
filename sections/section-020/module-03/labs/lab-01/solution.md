# Solution: Allow Only One Client To Export

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the decisions from both clients, the client policy, and the original permissions.

## Step 1: Define the helpers

The token request inside `user_token_via` uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=clients-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
AUTHZ="clients/$CLIENT_ID/authz/resource-server"
authz_id() {
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
}
client_uuid() { kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes; }
user_token_via() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=$1 \
      -d username=$2 -d password=$2-password | jq -r .access_token"
}
decision_via() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $(user_token_via "$1" "$2")" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$3" -d response_mode=decision
}
```

## Step 2: Create the client policy

The policy takes the internal id of the client, not its name.

```sh
kcadm create "$AUTHZ/policy/client" -r inventory \
  -s name=billing-cli-only -s logic=POSITIVE \
  -s "clients=[\"$(client_uuid billing-cli)\"]"
```

## Step 3: Create the permission

```sh
kcadm create "$AUTHZ/permission/scope" -r inventory \
  -s name=export-invoices -s type=scope -s decisionStrategy=UNANIMOUS \
  -s "resources=[\"$(authz_id resource invoices)\"]" \
  -s "scopes=[\"$(authz_id scope export)\"]" \
  -s "policies=[\"$(authz_id policy billing-cli-only)\"]"
```

## Step 4: Prove it

```sh
echo "billing-cli   $(decision_via billing-cli alice invoices#export)"
echo "inventory-cli $(decision_via inventory-cli alice invoices#export)"
```

The first answer is `200` and the second is `403`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A role policy for `inventory-manager` | `alice` is granted from both clients, so the second decision is wrong |
| `PERMISSIVE` enforcement mode | Every client is granted |
| Adding `billing-cli` to an existing permission | The original permissions check fails |
