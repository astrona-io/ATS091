#!/usr/bin/env bash
# PASS when staff-in-business-hours is a UNANIMOUS aggregated policy of a group
# policy for staff and business-hours, and delete-items uses only it.
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

AGGREGATED_ID="$(authz_id policy staff-in-business-hours)"
if [ -z "$AGGREGATED_ID" ]; then
  echo "FAIL: there is no policy named staff-in-business-hours."
  exit 1
fi
DETAILS="$(kcadm get "$(authz_path)/policy/$AGGREGATED_ID" -r inventory --fields type,decisionStrategy --format csv --noquotes)"
if [ "$DETAILS" != "aggregate,UNANIMOUS" ]; then
  echo "FAIL: staff-in-business-hours is '$DETAILS', expected an aggregate policy with UNANIMOUS."
  exit 1
fi
MEMBERS="$(associated_policy_names staff-in-business-hours | tr '\n' ' ')"
if [ "$MEMBERS" != "business-hours staff-members " ]; then
  echo "FAIL: staff-in-business-hours combines '$MEMBERS', expected business-hours and staff-members."
  exit 1
fi
GROUP_TYPE="$(kcadm get "$(authz_path)/policy/$(authz_id policy staff-members)" -r inventory --fields type --format csv --noquotes)"
if [ "$GROUP_TYPE" != "group" ]; then
  echo "FAIL: staff-members is a '$GROUP_TYPE' policy, not a group policy."
  exit 1
fi
DELETE_POLICIES="$(associated_policy_names delete-items | tr '\n' ' ')"
if [ "$DELETE_POLICIES" != "staff-in-business-hours " ]; then
  echo "FAIL: delete-items uses '$DELETE_POLICIES', expected only staff-in-business-hours."
  exit 1
fi
echo "PASS: delete-items uses the UNANIMOUS aggregate of staff-members and business-hours."
exit 0
