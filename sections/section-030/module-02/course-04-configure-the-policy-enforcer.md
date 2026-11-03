# Configure The Policy Enforcer

A resource server that calls the Protection API for every resource and every request would repeat the same code in every application. Keycloak adapters solve this with a **policy enforcer**: a component inside the application that acts as the policy enforcement point. It reads a configuration, matches each incoming request to a path, asks Keycloak for a decision and lets the request through or refuses it. This part reads the configuration that Keycloak generates for a client and explains the fields that change the enforcer's behaviour.

## Get the generated configuration

The Admin Console has a tab **Action** and the item **Download adapter config** on the client page. It builds the file that an adapter reads. The Admin REST API gives the same file at `clients/<id>/installation/providers/keycloak-oidc-keycloak-json`. Fetch it for the resource server:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=protection-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
API_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
kcadm get "clients/$API_ID/installation/providers/keycloak-oidc-keycloak-json" -r inventory
```

The file contains the realm name, the address of the server (`auth-server-url`), the client ID in `resource`, the client secret in `credentials` and the field `policy-enforcer`. The secret appears in the file, so treat it like a password. For a resource server, the field `policy-enforcer` is an object that you can extend.

## The fields that matter

The `policy-enforcer` object controls how the enforcer matches requests and what it does when a decision is missing. These are the fields most often set:

| Field | What it does |
| --- | --- |
| `enforcement-mode` | `ENFORCING` denies a request to a path with no matching resource; `PERMISSIVE` lets it through; `DISABLED` turns the enforcer off |
| `paths` | A list that maps a path (and optionally HTTP methods) to a resource name and its scopes |
| `lazy-load-paths` | `true` makes the enforcer look up the resource for a path in Keycloak when it first sees the path, instead of reading all resources at start |
| `http-method-as-scope` | `true` treats the HTTP method (`GET`, `POST`) as the scope of the request |
| `path-cache` | Settings for the cache of the path to resource mapping |
| `claim-information-point` | Sources of extra claims that the enforcer sends with a decision request |
| `on-deny-redirect-to` | A page to send the user to when Keycloak denies a request |

The fields belong to the adapter, not to the Keycloak server. Setting `enforcement-mode` here changes what the enforcer does in the application; it does not change the policy enforcement mode of the resource server in Keycloak. The two modes live in different places and can differ.

## Map methods to scopes

The example API in this course maps `GET`, `POST` and `DELETE` on `/items` to the scopes `view`, `edit` and `delete`. With a policy enforcer, you write this map in `paths` and the enforcer applies it. A `paths` entry can list the methods and their scopes:

```json
{
  "policy-enforcer": {
    "enforcement-mode": "ENFORCING",
    "paths": [
      {
        "path": "/items/*",
        "name": "items",
        "methods": [
          { "method": "GET", "scopes": ["view"] },
          { "method": "POST", "scopes": ["edit"] },
          { "method": "DELETE", "scopes": ["delete"] }
        ]
      }
    ]
  }
}
```

The file shows a request `DELETE /items/7` in the path `/items/*`. The enforcer picks the resource `items`, picks the scope `delete` from the method and asks Keycloak for the decision `items#delete`. A path with no entry is denied in `ENFORCING` mode. The Keycloak server does not change anything for this: the decision request is the same `uma-ticket` request you sent from the terminal.

## What the enforcer replaces

Without an enforcer, the API code does four things by hand: it reads the bearer token, answers `401` with a ticket when the token is missing a permission, sends the decision request and maps the answer to `200` or `403`. The enforcer does all four from its configuration. The price is that the behaviour is spread over two places: the configuration in the application and the permissions in Keycloak. When a request is wrong, check both: evaluate the decision in Keycloak first, then check that the `paths` entry maps the request to the scope you expect.

You can now read the enforcer configuration of a client and say what each main field does. The resource server registers its resources, the users share them and the enforcer maps requests to scopes: together, they close the loop of enforcement.

## Common pitfalls

> [!WARNING]
> - **Confusing the two enforcement modes.** The `enforcement-mode` in the adapter and the policy enforcement mode of the resource server are separate settings.
> - **Publishing the adapter file.** It contains the client secret. Keep it out of version control.
> - **Leaving a path without an entry in `PERMISSIVE` mode.** The enforcer then lets the request through without a decision.
> - **Mapping a method to the wrong scope.** A `POST` mapped to `view` lets a viewer create items. Test each method with a decision request.
