# Solution: Fix A Policy Set That Decides For The Wrong Users

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the decisions for the three users, that the policies are the originals and still combined, and that the users are unchanged.

## Step 1: Define the helpers and look at the decisions

The token request inside `decision` uses the password grant, which is only for terminal testing.

```sh
NAMESPACE=policiescapstone-demo
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
for user in alice bob carol; do echo "$user delete $(decision $user items#delete)"; done
```

`alice` gets `403`, and `bob` and `carol` get `200`: the exact opposite of the table.

## Step 2: Read the three policies

```sh
kcadm get $AUTHZ/policy/$(authz_id policy staff-with-company-email) -r inventory --fields name,type,logic,decisionStrategy
kcadm get $AUTHZ/policy/group/$(authz_id policy staff-members) -r inventory --fields name,logic
kcadm get $AUTHZ/policy/regex/$(authz_id policy company-email) -r inventory --fields name,targetClaim,pattern,logic
```

Three settings are wrong:

- `staff-with-company-email` uses `AFFIRMATIVE`, so one granting policy is enough. The rule is "and", so it needs `UNANIMOUS`.
- `staff-members` has the logic `NEGATIVE`, so it grants to everyone **outside** `staff`. That is why `bob` gets through.
- `company-email` matches `^.+@example\.org$`, the wrong domain. That is why `carol` gets through and `alice` does not.

## Step 3: Fix each one in place

```sh
kcadm update $AUTHZ/policy/aggregate/$(authz_id policy staff-with-company-email) -r inventory -s decisionStrategy=UNANIMOUS
kcadm update $AUTHZ/policy/group/$(authz_id policy staff-members) -r inventory -s logic=POSITIVE
kcadm update $AUTHZ/policy/regex/$(authz_id policy company-email) -r inventory -s 'pattern=^.+@example\.com$'
```

## Step 4: Prove it

```sh
for user in alice bob carol; do echo "$user delete $(decision $user items#delete)"; done
for user in alice bob; do echo "$user view $(decision $user items#view)"; done
```

`alice` gets `200` for delete; `bob` and `carol` get `403`. Both `alice` and `bob` still get `200` for view.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the decision strategy | `bob` is denied, but so is `alice`, because the regex still matches `example.org` and the group policy is still negative |
| Remove `company-email` from the aggregate | `carol` may delete; the grader requires both conditions |
| Change `carol`'s email or remove her from `staff` | The decisions come out right for the wrong reason; the grader requires the users unchanged |
