# Summary

User-Managed Access (UMA) 2.0 extends OAuth 2.0 with a way for an API to say what a refused request needs. The resource server uses a protection API token (PAT), a token of its own service account with the scope `uma_protection`, to call Keycloak's Protection API. It creates a permission ticket that names a resource and its scopes, and answers the client with `401` and a `WWW-Authenticate: UMA` header holding `realm`, `as_uri` and `ticket`. The client exchanges the ticket with the `uma-ticket` grant and receives a requesting party token (RPT), or a `403` when Keycloak denies. The RPT carries the granted permissions in its `authorization` claim.

User-Managed Access also lets users own resources. The realm setting `userManagedAccessAllowed` switches it on, and a resource with an `owner` and `ownerManagedAccess` set to `true` can be shared by its owner. The owner shares from **My Resources** in the Account Console, which grants a permission ticket for one requesting user and one scope. The owner always has access to their own resource; everyone else needs a permission or a granted ticket.

A policy enforcement point is the code in an API that maps each request to a resource and a scope, asks Keycloak, and enforces the answer. The `inventory-api` maps `GET`, `POST` and `DELETE` to `view`, `edit` and `delete` on `items`, and asks with the user's token, an `audience` and `response_mode=decision`. A correct model can still give wrong answers when the API asks the wrong question, so a wrong answer is traced in order: the API's log, the same question asked of Keycloak directly, and then either the API's settings or the model. The key facts to remember are these:

- A PAT, not a user's token, calls the Protection API.
- A ticket names what a request needs; the RPT is what grants it.
- The resource name, the scopes and the audience must match between the API and Keycloak.
- `401` means no valid token; `403` means denied.

<!-- astrona:playground:destroy -->
