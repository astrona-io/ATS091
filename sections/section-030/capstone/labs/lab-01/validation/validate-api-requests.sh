#!/usr/bin/env bash
# PASS when inventory-api answers every request the way the access rules say:
# viewers may GET, only managers may POST and DELETE, and no token gets 401.
set -uo pipefail

NAMESPACE="umacapstone-demo"

# ---- shared helpers (same in every ATS091 script) ----
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  # The session expires and a pod restart deletes /tmp/kcadm.config, so sign in again each time.
  for _ in $(seq 1 30); do
    kcadm config credentials --server http://localhost:8080 --realm master \
      --user admin --password admin >/dev/null 2>&1 && return 0
    sleep 5
  done
  echo "could not sign kcadm.sh in to the master realm" >&2
  return 1
}
client_uuid() { kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes; }
user_uuid() { kcadm get users -r inventory -q username="$1" -q exact=true --fields id --format csv --noquotes; }
group_uuid() { kcadm get groups -r inventory -q search="$1" -q exact=true --fields id --format csv --noquotes | head -n 1; }
role_uuid() { kcadm get "roles/$1" -r inventory --fields id --format csv --noquotes; }
authz_path() { echo "clients/$(client_uuid inventory-api)/authz/resource-server"; }
authz_id() {
  # authz_id resource|scope|policy NAME -> id of that authorization object (empty when missing)
  local field=id
  [ "$1" = resource ] && field=_id
  kcadm get "$(authz_path)/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes 2>/dev/null
}
user_token() {
  # The password grant is only for terminals and graders; a real application uses the authorization code flow.
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=$1 -d password=$1-password | jq -r .access_token"
}
decision() {
  # decision USER RESOURCE#SCOPE -> HTTP status of a uma-ticket decision request (200 granted, 403 denied)
  local token
  token="$(user_token "$1")"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $token" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=inventory-api -d permission="$2" -d response_mode=decision
}

kcadm_login || { echo "FAIL: could not sign in to Keycloak."; exit 1; }

# ---- inventory-api helpers ----
wait_for_api() { kubectl -n "$NAMESPACE" rollout status deployment/inventory-api --timeout=300s; }
api_status() {
  # api_status USER METHOD -> HTTP status of METHOD /items on inventory-api with USER's token ("none" for no token)
  local header=""
  [ "$1" != none ] && header="Authorization: Bearer $(user_token "$1")"
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}' \
    -X "$2" ${header:+-H "$header"} http://inventory-api:3000/items
}
code_checksum() { kubectl -n "$NAMESPACE" get configmap inventory-api-code -o jsonpath='{.data.server\.js}' | cksum; }

FAILED=0
check() {
  # check USER METHOD EXPECTED
  local got
  got="$(api_status "$1" "$2")"
  if [ "$got" != "$3" ]; then
    echo "FAIL: $2 /items as $1 returned $got, expected $3."
    FAILED=1
  fi
}
check alice GET 200
check bob GET 200
check alice POST 200
check bob POST 403
check alice DELETE 200
check bob DELETE 403
check none GET 401
[ "$FAILED" -eq 0 ] || exit 1
echo "PASS: inventory-api lets viewers read, and only managers change or delete items."
exit 0
