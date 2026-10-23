#!/usr/bin/env bash
# OS prep for the "Protect An API With Keycloak Authorization Services" playground (`ats-091-playground-010-01`).
# 
# Environment preparation only. There is no task and no grading. This script:
#   1. applies Keycloak 26.8.1 and the tester pod,
#   2. creates the realm inventory with alice, bob, their roles, the group staff,
#      the public client inventory-cli and the confidential client inventory-api.
# Authorization is NOT switched on for inventory-api: the reader does that.
set -euo pipefail

NAMESPACE="model-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# lab-start.yaml may also be listed under bootstrap.manifests; kubectl apply is idempotent.
echo "[setup] Applying the starting workloads..."
# lab-start.yaml holds the namespace; apply it first, because the loop runs
# in alphabetical order and other manifests need the namespace.
[ -f "$MANIFEST_DIR/lab-start.yaml" ] && kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
for manifest in "$MANIFEST_DIR"/*.yaml; do kubectl apply -f "$manifest"; done

# The first rollout pulls a large image, and Keycloak takes a while to start.
echo "[setup] Waiting for Keycloak (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

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

# ---- the inventory realm, its users, roles, group and clients ----
create_user() {
  # create_user NAME EMAIL
  [ -n "$(user_uuid "$1")" ] && return 0
  kcadm create users -r inventory -s username="$1" -s enabled=true \
    -s email="$2" -s emailVerified=true -s firstName="$1" -s lastName=Example
  kcadm set-password -r inventory --username "$1" --new-password "$1-password"
}
add_to_group() {
  # add_to_group USER GROUP
  local user_id group_id
  user_id="$(user_uuid "$1")"
  group_id="$(group_uuid "$2")"
  kcadm update "users/$user_id/groups/$group_id" -r inventory \
    -s realm=inventory -s userId="$user_id" -s groupId="$group_id" -n
}
seed_realm() {
  kcadm get realms/inventory >/dev/null 2>&1 || kcadm create realms -s realm=inventory -s enabled=true
  for role in inventory-viewer inventory-manager; do
    kcadm get "roles/$role" -r inventory >/dev/null 2>&1 || kcadm create roles -r inventory -s name="$role"
  done
  [ -n "$(group_uuid staff)" ] || kcadm create groups -r inventory -s name=staff
  create_user alice alice@example.com
  create_user bob bob@example.com
  kcadm add-roles -r inventory --uusername alice --rolename inventory-viewer --rolename inventory-manager
  kcadm add-roles -r inventory --uusername bob --rolename inventory-viewer
  add_to_group alice staff
  if [ -z "$(client_uuid inventory-cli)" ]; then
    kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
      -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
  fi
  if [ -z "$(client_uuid inventory-api)" ]; then
    kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
      -s publicClient=false -s serviceAccountsEnabled=true -s secret=inventory-api-secret \
      -s standardFlowEnabled=false -s directAccessGrantsEnabled=false
  fi
}

kcadm_login
echo "[setup] Creating the inventory realm, its users, roles and clients..."
seed_realm

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
