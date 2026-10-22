# Why Roles In A Token Are Not Enough

Most APIs start with a simple check: read the roles in the access token, and allow the request if the right role is there. That works for the first rule. It stops working when the rules grow, because each API keeps its own copy of them in code. This part shows what a role check can and cannot express, and then switches on the Keycloak feature that keeps the rules in one place.

## What the token already says

An access token is a token a client sends to an API to show what it may do. Keycloak puts the user's realm roles into the access token, in the claim `realm_access.roles`. So the first step is to look at what the API would see.

The helpers below run `kcadm.sh` inside the Keycloak pod and request a token for a user from the `tester` pod. `kcadm.sh` is Keycloak's administration command-line tool; it calls the Admin REST API. The token request uses the password grant, where the client sends the user's password to the token endpoint. A real application never does this, and OAuth 2.1 drops the password grant; it is used here only so you can get a user's token from a terminal.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=model-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=$1 -d password=$1-password | jq -r .access_token"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Now decode the payload of `bob`'s token and print his roles. A JSON Web Token (JWT) has three Base64URL parts separated by dots, and the middle part is the payload:

```sh
user_token bob | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq '.realm_access.roles'
```

The list holds `inventory-viewer` and Keycloak's default realm roles, such as `offline_access` and `uma_authorization`. The base64 tool may warn about missing padding at the end of the payload; the JSON still prints. Run the same command for `alice`, and her list also holds `inventory-manager`.

## What a role check cannot say

With these tokens, an API can implement "managers may delete" in one line of code. Now look at rules that real teams ask for a few months later:

- Managers may delete items, but only between 08:00 and 18:00.
- Staff may edit items only if their email address belongs to the company.
- A user may share one of their own items with one other user.

None of these fit in a role. The first needs the time, the second needs an attribute of the user, and the third needs to know who owns which item. Each API that implements them in code holds its own copy, and the copies drift apart. These are three ways to control access, and they are worth naming:

| Model | What it decides on | Where the rule lives in this course |
| --- | --- | --- |
| Role-based access control (RBAC) | The roles the user has | A role policy |
| Attribute-based access control (ABAC) | Attributes of the user, the resource or the request, for example the email address or the time | A regex policy, a time policy |
| Policy-based access control (PBAC) | Any combination of the above, written as named policies outside the application | Policies combined by permissions |

Keycloak Authorization Services implements policy-based access control. The rules live in Keycloak, next to the users. The API only asks one question per request: may this token use this scope on this resource?

## Switch on authorization for inventory-api

A client becomes a resource server when you switch on authorization for it. Keycloak only allows this for a confidential client, a client that can keep a secret. `inventory-api` is one, and it already has a service account.

First check the two settings that make this possible, then switch authorization on:

```sh
API_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
kcadm get clients/$API_ID -r inventory --fields clientId,publicClient,serviceAccountsEnabled,authorizationServicesEnabled
kcadm update clients/$API_ID -r inventory -s authorizationServicesEnabled=true
```

The first `get` shows `publicClient` as `false`, `serviceAccountsEnabled` as `true`, and no `authorizationServicesEnabled` value yet. After the `update`, the client has a resource server. Its settings live under the path `clients/<id>/authz/resource-server` of the Admin REST API, so save that path once:

```sh
AUTHZ="clients/$API_ID/authz/resource-server"
kcadm get $AUTHZ -r inventory --fields policyEnforcementMode,decisionStrategy
```

The resource server is in the `ENFORCING` mode, with the decision strategy `UNANIMOUS`. Both are the defaults, and both matter later. To keep a new resource server from being empty, Keycloak also adds a default resource, a default policy and a default permission. List them so you know they are there:

```sh
kcadm get $AUTHZ/resource -r inventory --fields name,type
kcadm get $AUTHZ/policy -r inventory --fields name,type
```

The default objects protect a default resource type, not the resource you create next, so they do not change the decisions in this module. In the Admin Console, the same objects appear on the **Authorization** tab of the client `inventory-api`, which appears once authorization is switched on.

You now know what a role in a token can express, why rules about time, attributes and ownership do not fit in a role, and how a client becomes a resource server. The resource server is still empty of your own resources. The open question is how to describe the inventory API to Keycloak, so that Keycloak can protect each of its actions.

## Common pitfalls

> [!WARNING]
> - **Switching on authorization for a public client.** Keycloak refuses it. The resource server must be a confidential client with a service account.
> - **Thinking the roles in a token are the decision.** They are an input. With Authorization Services, the decision comes from Keycloak's policies, not from the API's code.
> - **Turning authorization off to "reset" a client.** Switching `authorizationServicesEnabled` off removes the resource server with all its resources, policies and permissions.
> - **Reading the token payload as if it were secret.** Anyone who holds a token can decode it. Never paste a real token into a public place.
