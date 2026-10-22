# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** the authorization model

## Scenario

`inventory-api` in the namespace `modelcapstone-demo` had a complete authorization model: viewers may view items, managers may edit and delete them. Last week someone "fixed" a complaint in a hurry. Since then, `bob`, who only holds the role `inventory-viewer`, can delete items, and the audit team is not happy.

The intended rules have not changed:

| Action on items | Allowed for |
| --- | --- |
| view | users with the realm role `inventory-viewer` |
| edit | users with the realm role `inventory-manager` |
| delete | users with the realm role `inventory-manager` |

## Your task

Find every change that makes the resource server allow more than these rules, and fix each one. Several independent things are wrong. Use decision requests to see the current behaviour before you change anything, and again after each change.

## Constraints

- **Correct the permission `delete-items`; do not delete and recreate it.** The grader checks that it is the same permission.
- Do not remove roles from users and do not change the users. The users are right; the model is not.
- The policy enforcement mode must not be `PERMISSIVE` or `DISABLED`.
- Use role policies for every permission you create.

## Done when

- `alice` is granted `items#view`, `items#edit` and `items#delete`.
- `bob` is granted `items#view` and denied `items#edit` and `items#delete`.
- The resource server is in `ENFORCING` mode, and `delete-items` is the original permission.
