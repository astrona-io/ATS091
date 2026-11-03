# Summary

The Protection API is the interface a resource server uses to manage resources and sharing in Keycloak. The resource server signs in with its client credentials, gets a protection API token (PAT) with the scope `uma_protection`, and calls paths under `/realms/<realm>/authz/protection`. A user token does not work there.

A resource has a life cycle that the resource server drives. A `POST` request to `resource_set` registers it with a name, a type, URIs, scopes and optionally an owner. A `GET` request reads it, a `PUT` request replaces it with the body sent, and a `DELETE` request removes it. The list call returns resource ids, and query parameters (`name`, `exactName`, `uri`, `owner`, `type`, `scope`, `first`, `max` and `deep`) narrow the list so an application finds the resource it needs.

Sharing is stored as permission tickets. A ticket names a resource, a requester and a scope, and has a `granted` flag. The resource server lists tickets with `resourceId` and `returnNames=true`, and revokes one scope by deleting one ticket. Deleting the resource removes access for everyone, so it is the wrong tool to reduce sharing.

A policy enforcer is configuration for the policy enforcement point in an application. The `policy-enforcer` object maps paths and HTTP methods to resources and scopes, sets the enforcer's own mode and controls how resources are loaded. The enforcer's mode is separate from the policy enforcement mode of the resource server. The adapter configuration file holds the client secret and must be protected.

Key facts to remember:

- The Protection API takes a PAT, not a user token.
- A `PUT` request replaces a resource; send the full body.
- Revoke one scope by deleting one ticket.
- The enforcer's `enforcement-mode` is not the resource server's policy enforcement mode.

<!-- astrona:playground:destroy -->
