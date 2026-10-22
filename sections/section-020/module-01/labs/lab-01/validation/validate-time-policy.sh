#!/usr/bin/env bash
# PASS when the time policy business-hours exists and limits the hour to 8 through 17.
set -uo pipefail

NAMESPACE="policies-demo"

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

POLICY_ID="$(authz_id policy business-hours)"
if [ -z "$POLICY_ID" ]; then
  echo "FAIL: there is no policy named business-hours."
  exit 1
fi
TYPE="$(kcadm get "$(authz_path)/policy/$POLICY_ID" -r inventory --fields type --format csv --noquotes)"
if [ "$TYPE" != "time" ]; then
  echo "FAIL: business-hours is a '$TYPE' policy, not a time policy."
  exit 1
fi
HOURS="$(kcadm get "$(authz_path)/policy/time/$POLICY_ID" -r inventory --fields hour,hourEnd --format csv --noquotes)"
if [ "$HOURS" != "8,17" ]; then
  echo "FAIL: business-hours has hour,hourEnd = '$HOURS', expected 8,17."
  exit 1
fi
echo "PASS: business-hours is a time policy for the hours 8 to 17."
exit 0
