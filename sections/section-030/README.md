# Section 030: UMA 2.0 And Policy Enforcement

A decision in Keycloak protects nothing until an API acts on it. Somewhere in the API, code must ask Keycloak, read the answer and refuse the request when the answer is no. That code is the policy enforcement point, and it is where a correct model in Keycloak can still be undone by one wrong setting in the API.

This section covers the two sides. First the protocol: User-Managed Access (UMA) 2.0, where a resource server asks Keycloak for a permission ticket and a client exchanges it for a requesting party token, and where users share their own resources with each other. Then the code: a small API that asks Keycloak for a decision on every request, and what happens when the API or the model around it is wrong.

**Topic covered:** UMA 2.0 and policy enforcement

## What you will learn

- The UMA 2.0 flow: the `401` with a permission ticket, the exchange for a requesting party token (RPT), and the Protection API.
- The protection API token (PAT) and the `uma_protection` role of a resource server.
- User-Managed Access: resources owned by a user, and sharing them with another user.
- How a policy enforcement point in an API maps HTTP methods to scopes and asks Keycloak for a decision.
- How to trace a wrong answer from the API back to the setting that caused it, in the API or in Keycloak.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, and the landing page starts it for you.

### 1. Enforce Decisions In An API With UMA 2.0

The playground holds Keycloak with the realm `inventory`, the full authorization model on `inventory-api`, and the `inventory-api` service itself, a small HTTP API that asks Keycloak for a decision on every request.

1. UMA 2.0, Permission Tickets And The RPT
2. User-Managed Access And Sharing
3. A Policy Enforcement Point In An API, followed by the lab **Make The API Refuse Deletes For Viewers**
4. Summary

## Section capstone: Make The Inventory API Enforce Its Rules

The capstone is one graded scenario that uses the whole module. `inventory-api` answers almost every request wrongly. Some faults are in the API's settings and some are in the authorization model in Keycloak, and you must not change the API's code. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-091-capstone-030
```
