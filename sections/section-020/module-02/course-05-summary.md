# Summary

The evaluation tool is the `POST` path `policy/evaluate` under a resource server in the Admin REST API. It runs the policies of the resource server for a user, a client and a list of resources and scopes, and it returns the same result a real decision request gets. The answer is richer than `200` or `403`: it holds a status for each resource, the scopes that were granted, the permissions that matched and the policies each permission uses. All ids in the request are Keycloak internal ids.

A denial is traced from the top down. The permission is denied because a policy it uses is denied, and an aggregated policy is denied because one of its policies is denied when its strategy is `UNANIMOUS`. The lowest `DENY` in the tree is the cause, and the fix belongs there. A fix at a higher level, such as removing a policy from a permission, opens access for everyone the policy stopped.

The tool also answers questions that a real request cannot. The field `roleIds` evaluates a user with extra roles, the field `clientId` evaluates the same user for another client, and `context` attributes such as `kc.time.date_time` move the clock for time policies. None of these changes the realm. This makes the tool the right place to test a new rule before a user depends on it.

With `entitlements` set to `true`, the tool lists every permission of a user, as the requesting party token would carry them. A live `uma-ticket` request with `response_mode=permissions` returns the same facts for the user who owns the token. When the two differ, the cause is in the input: the `audience`, the token, the client or the ids in the request file.

Key facts to remember:

- The evaluation tool needs administrator access and ids, not a user token.
- The lowest `DENY` in the tree of policies is the cause of a denial.
- `roleIds`, `clientId` and `context` give what-if answers without changing the realm.
- The tool proves what the model decides, not what an API does with the decision.

<!-- astrona:playground:destroy -->
