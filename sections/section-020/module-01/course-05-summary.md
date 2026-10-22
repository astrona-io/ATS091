# Summary

A policy is a rule that reads one kind of input and grants or denies. Role policies read the user's roles. User policies list accounts by id, and group policies list groups by id, with `extendChildren` to include subgroups. Client policies check the client the user's token was issued to. Regex policies match one claim, such as `email`, against a regular expression, which is the simplest form of attribute-based access control. Every policy has a logic: `POSITIVE` keeps the result, and `NEGATIVE` turns it around, which also grants to every user who fails the original check.

Time policies read the server's clock, which is UTC in the container. Their fields describe a window, and every field you set must hold at the same time. Because the result depends on when a request arrives, a test of a time policy must look at the time, or use a user whose result does not depend on it. Aggregated policies combine other policies with a decision strategy, and `UNANIMOUS` means every policy must grant.

JavaScript policies cover rules that no built-in type expresses. They cannot be uploaded through the Admin Console or the REST API by default. They are deployed in a JAR with `META-INF/keycloak-scripts.json`, copied to `providers/`, built into the server with `kc.sh build`, and enabled with the preview feature `scripts`.

An API asks for a decision with the `uma-ticket` grant at the token endpoint, with the resource server as `audience` and `RESOURCE#SCOPE` as `permission`. `response_mode=decision` returns `{"result": true}`, `response_mode=permissions` returns a list of resources and scopes, and no `response_mode` returns a requesting party token whose `authorization` claim holds the permissions. A denial is always `403` with `access_denied`. The key facts to remember are these:

- Each policy type reads one input; an aggregated policy combines several.
- Negative logic grants to everyone the original policy denies.
- Time policies use the server's UTC clock.
- An RPT's permissions are fixed when it is issued.

<!-- astrona:playground:destroy -->
