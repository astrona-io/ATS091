#!/usr/bin/env bash
# OS prep for the "Write Policies That Decide Access" playground (`ats-091-playground-020-01`).
# 
# Environment preparation only. There is no task and no grading. This script
# deploys Keycloak 26.8.1 and the tester pod, creates the inventory realm with
# alice, bob, their roles, the group staff and the clients, and builds the full
# authorization model on inventory-api (scopes, the resource items, two role
# policies and three scope permissions), so the reader can add policies to it.
set -euo pipefail

NAMESPACE="policies-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# lab-start.yaml may also be listed under bootstrap.manifests; kubectl apply is idempotent.
echo "[setup] Applying the starting workloads..."
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

# ---- building blocks of the authorization model on inventory-api ----
enable_authz() {
  kcadm update "clients/$(client_uuid inventory-api)" -r inventory -s authorizationServicesEnabled=true
}
create_scopes() {
  for scope in view edit delete; do
    [ -n "$(authz_id scope "$scope")" ] || kcadm create "$(authz_path)/scope" -r inventory -s name="$scope"
  done
}
create_items_resource() {
  # create_items_resource SCOPE... (the scopes the resource lists)
  [ -n "$(authz_id resource items)" ] && return 0
  local scopes="" scope
  for scope in "$@"; do scopes="$scopes{\"id\":\"$(authz_id scope "$scope")\"},"; done
  kcadm create "$(authz_path)/resource" -r inventory -s name=items \
    -s type=urn:inventory-api:resources:item -s 'uris=["/items","/items/*"]' \
    -s "scopes=[${scopes%,}]"
}
create_role_policy() {
  # create_role_policy POLICY ROLE
  [ -n "$(authz_id policy "$1")" ] && return 0
  kcadm create "$(authz_path)/policy/role" -r inventory -s name="$1" -s logic=POSITIVE \
    -s decisionStrategy=UNANIMOUS -s "roles=[{\"id\":\"$(role_uuid "$2")\",\"required\":false}]"
}
create_scope_permission() {
  # create_scope_permission PERMISSION SCOPE STRATEGY POLICY...
  [ -n "$(authz_id policy "$1")" ] && return 0
  local name="$1" scope="$2" strategy="$3" policies="" policy
  shift 3
  for policy in "$@"; do policies="$policies\"$(authz_id policy "$policy")\","; done
  kcadm create "$(authz_path)/permission/scope" -r inventory -s name="$name" \
    -s decisionStrategy="$strategy" -s "resources=[\"$(authz_id resource items)\"]" \
    -s "scopes=[\"$(authz_id scope "$scope")\"]" -s "policies=[${policies%,}]"
}
set_enforcement_mode() {
  kcadm update "$(authz_path)" -r inventory -s policyEnforcementMode="$1"
}
seed_full_model() {
  # The complete, correct model: viewers view, managers edit and delete.
  enable_authz
  create_scopes
  create_items_resource view edit delete
  create_role_policy inventory-viewers inventory-viewer
  create_role_policy inventory-managers inventory-manager
  create_scope_permission view-items view UNANIMOUS inventory-viewers
  create_scope_permission edit-items edit UNANIMOUS inventory-managers
  create_scope_permission delete-items delete UNANIMOUS inventory-managers
  set_enforcement_mode ENFORCING
}
create_group_policy() {
  # create_group_policy POLICY GROUP [LOGIC]
  [ -n "$(authz_id policy "$1")" ] && return 0
  kcadm create "$(authz_path)/policy/group" -r inventory -s name="$1" -s logic="${3:-POSITIVE}" \
    -s "groups=[{\"id\":\"$(group_uuid "$2")\",\"extendChildren\":false}]"
}
create_aggregated_policy() {
  # create_aggregated_policy POLICY STRATEGY POLICY...
  [ -n "$(authz_id policy "$1")" ] && return 0
  local name="$1" strategy="$2" policies="" policy
  shift 2
  for policy in "$@"; do policies="$policies\"$(authz_id policy "$policy")\","; done
  kcadm create "$(authz_path)/policy/aggregate" -r inventory -s name="$name" -s logic=POSITIVE \
    -s decisionStrategy="$strategy" -s "policies=[${policies%,}]"
}
set_permission_policies() {
  # set_permission_policies PERMISSION STRATEGY POLICY...
  local permission_id="$(authz_id policy "$1")" strategy="$2" policies="" policy
  shift 2
  for policy in "$@"; do policies="$policies\"$(authz_id policy "$policy")\","; done
  kcadm update "$(authz_path)/permission/scope/$permission_id" -r inventory \
    -s decisionStrategy="$strategy" -s "policies=[${policies%,}]"
}
associated_policy_names() {
  # associated_policy_names POLICY -> sorted names, one per line
  kcadm get "$(authz_path)/policy/$(authz_id policy "$1")/associatedPolicies" -r inventory \
    --fields name --format csv --noquotes | sort
}

kcadm_login
echo "[setup] Creating the inventory realm and the authorization model..."
seed_realm
seed_full_model
echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
