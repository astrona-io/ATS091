# Summary

A decision depends on more than the person. Keycloak can also check the application that sent the request, and the scopes that the application asked for. A client policy grants a request when the client behind it is in a list. It reads the client from the token and takes internal client ids. A client scope policy grants a request when the token carries the listed client scopes, and its `required` flag says whether a scope must be present.

The two policies follow the same rules as every other policy. A policy protects nothing until a permission uses it. A permission names the policies it needs and a decision strategy. The proof is a pair of decision requests: one from the client or scope that must be granted and one from a client or scope that must be denied, for the same user.

A client policy is a blunt rule. The whole client is in or out, and it says nothing about the person. A client scope policy is finer, because the same client can be granted for one request and denied for the next, depending on the scope in the token. Making a scope a default scope removes that difference, because every token then carries it.

The choice between policy types follows the fact that the rule is about. Roles, users and groups describe the person. Clients describe the application. Client scopes describe the request. An aggregated policy combines them when a rule needs two facts.

Key facts to remember:

- A client policy and a client scope policy take internal ids.
- The same user can be granted from one client and denied from another.
- An optional client scope is in the token only when the request names it.
- A default client scope is in every token.

<!-- astrona:playground:destroy -->
