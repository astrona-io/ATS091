# Summary

Four components make up the authorization architecture. The policy enforcement point is the code in the API that asks and then allows or refuses. The policy decision point is the Keycloak service that evaluates policies and answers grant or deny. The policy administration point is where the model is written, which is the Admin Console and the Admin REST API. The policy information point supplies the facts a decision needs, such as roles, groups, token claims and the clock. A decision can change when the facts change, even when no policy changes.

A resource server has three settings that apply to all its objects. The policy enforcement mode decides what happens when no permission matches: `ENFORCING` denies, `PERMISSIVE` grants and `DISABLED` grants everything without evaluating any policy. The decision strategy of the resource server combines the results of several permissions that match one request, while the strategy on a permission combines its policies. Remote resource management lets the resource server manage its own resources through the Protection API.

Every tab of the Authorization page in the Admin Console is a call to the Admin REST API under `clients/<id>/authz/resource-server`. Lists exist for resources, scopes, policies and permissions, and the policy list also holds permissions. Objects refer to each other by id, and sub-paths answer which permissions use a policy, which policies a permission uses and what it protects.

The `settings` path exports the whole model as one JSON file, and the `import` path loads such a file into another resource server. Inside the file, objects refer to each other by name, so the file works in any realm that has the same role, group and client names. The file holds the model only, not users, roles, groups or clients. A faithful copy is proven by asking both servers the same questions and getting the same answers.

Key facts to remember:

- The API is the enforcement point; Keycloak is the decision point.
- `ENFORCING` is the only mode that fails closed.
- A permission is stored as a policy of a special type.
- Delete default objects in the target before an import that would repeat their names.

<!-- astrona:playground:destroy -->
