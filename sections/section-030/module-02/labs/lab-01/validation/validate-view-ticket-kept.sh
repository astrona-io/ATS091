#!/usr/bin/env bash
# PASS when exactly the view ticket remains for bob on alice-shelf, granted.
set -uo pipefail

NAMESPACE="protection-demo"

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
KEYCLOAK=http://keycloak:8080/realms/inventory
in_tester() { kubectl -n "$NAMESPACE" exec deploy/tester -- "$@"; }
pat() {
  in_tester sh -c "curl -s $KEYCLOAK/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-api \
    -d client_secret=inventory-api-secret | jq -r .access_token"
}
resource_id() {   # resource_id NAME -> id of the resource, empty when missing
  local id
  id="$(in_tester curl -s -H "Authorization: Bearer $(pat)" "$KEYCLOAK/authz/protection/resource_set?name=$1&exactName=true" | jq -r '.[0] // empty')"
  echo "$id"
}
SHELF_ID="$(resource_id alice-shelf)"
[ -n "$SHELF_ID" ] || { echo "FAIL: the resource alice-shelf was deleted."; exit 1; }
TICKETS="$(in_tester curl -s -H "Authorization: Bearer $(pat)" \
  "$KEYCLOAK/authz/protection/permission/ticket?resourceId=$SHELF_ID&returnNames=true" |
  jq -r '.[] | select(.granted==true) | .scopeName' | sort | tr '\n' ' ')"
[ "$TICKETS" = "view " ] || { echo "FAIL: granted tickets on alice-shelf are '$TICKETS', expected only 'view '."; exit 1; }
echo "PASS: only the view ticket is left."
exit 0
