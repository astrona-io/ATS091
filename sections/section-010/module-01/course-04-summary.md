# Summary

Keycloak Authorization Services moves access rules out of the API and into Keycloak. A role in a token is only one input. Rules about the time, about attributes of the user, or about who owns a resource do not fit in a role, and an API that writes them in its own code keeps a copy that drifts. With Authorization Services, the API asks one question per request, and Keycloak answers it.

A confidential client with a service account becomes a resource server when you switch on `authorizationServicesEnabled`. It holds four kinds of object. Scopes are actions, such as `view`, `edit` and `delete`. A resource is a thing to protect, with a type, URIs and the scopes that apply to it. A policy is a rule that grants or denies on its own, such as a role policy. A permission joins policies to resources or scopes, and only a permission protects anything. Objects refer to each other by id.

An API asks for a decision with the `uma-ticket` grant at the token endpoint. The request carries the user's access token, the resource server as `audience`, and the wanted `resource#scope` as `permission`. With `response_mode=decision`, Keycloak answers `200` when it grants and `403` with `access_denied` when it denies.

Two settings decide how the model fails. A decision strategy combines several results: `UNANIMOUS` needs all to grant, `AFFIRMATIVE` needs one, and `CONSENSUS` needs a majority, with a tie denying. The policy enforcement mode decides what happens when no permission matches: `ENFORCING` denies, `PERMISSIVE` grants, and `DISABLED` grants everything. The key facts to remember are these:

- A policy decides; a permission protects.
- `UNANIMOUS` is the default for permissions and for the resource server.
- `ENFORCING` is the default enforcement mode, and the only one that fails closed.
- A decision request without `audience` cannot name a permission.

<!-- astrona:playground:destroy -->
