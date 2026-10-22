# Section 010: The Authorization Services Model

A role in a token answers one question: what kind of user is this? It does not answer the question an API really has: may this user do this action on this thing, right now? Every API that only checks roles ends up with its own copy of the rules, written in its own code, and the copies drift apart.

Keycloak Authorization Services keeps those rules in one place. The API, called the resource server, describes what it protects (resources and scopes). Keycloak holds the rules (policies) and joins them to what they protect (permissions). The API then asks Keycloak for a decision. This section builds that model for one small API, from an empty client to a set of decisions you can prove.

**Topic covered:** the authorization model

## What you will learn

- The difference between role-based, attribute-based and policy-based access control, and what each one needs from the token.
- Switching on authorization for a confidential client, so it becomes a resource server.
- Creating scopes and a resource with URIs, and protecting each scope with a scope permission.
- Writing a role policy, and why a policy protects nothing until a permission uses it.
- Asking Keycloak for a decision with the `uma-ticket` grant, and reading `200` and `403` as granted and denied.
- The three decision strategies, `UNANIMOUS`, `AFFIRMATIVE` and `CONSENSUS`, and what each one does with several policies.
- The three policy enforcement modes, `ENFORCING`, `PERMISSIVE` and `DISABLED`, and why only one of them is safe.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Protect An API With Keycloak Authorization Services

The playground holds Keycloak with the realm `inventory`, the users `alice` (a viewer and a manager) and `bob` (a viewer), and the client `inventory-api`, which does not use authorization yet.

1. Why Roles In A Token Are Not Enough
2. Resources, Scopes And Permissions, followed by the lab **Model The Inventory API As A Resource Server**
3. Decision Strategies And The Enforcement Mode
4. Summary

## Section capstone: Close A Resource Server That Allows Too Much

The capstone is one graded scenario that uses the whole module. Someone "fixed" an access problem on `inventory-api` in a hurry. Now `bob`, who may only view items, can delete them, and nobody can edit them in the intended way. There are three independent faults. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-091-capstone-010
```
