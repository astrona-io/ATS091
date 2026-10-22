# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** policies

## Scenario

`inventory-api` in the namespace `policies-demo` has a role-based model: viewers view, managers edit and delete. After an item was deleted by accident late one evening, the security team set a new rule for deletes: only members of the group `staff`, and only during business hours, from hour 8 to hour 17 of the server's clock (UTC).

## Your task

1. Create a group policy named `staff-members` for the group `staff`.
2. Create a time policy named `business-hours` with the hour range 8 to 17.
3. Create an aggregated policy named `staff-in-business-hours` that grants only when **both** of these policies grant.
4. Change the permission `delete-items` so that it uses `staff-in-business-hours` as its only policy.

## Constraints

- Do not change the permissions `view-items` and `edit-items`.
- Do not change users, roles or group memberships.
- Keep the policy enforcement mode `ENFORCING`.

## Done when

- `business-hours` is a time policy with the hours 8 to 17.
- `staff-in-business-hours` is an aggregated policy with the decision strategy `UNANIMOUS` over `staff-members` (a group policy) and `business-hours`, and it is the only policy of `delete-items`.
- `bob` is denied `items#delete` at any hour, and the view and edit decisions for `alice` and `bob` are unchanged.

Whether `alice` may delete depends on the hour when you test, so the grader does not check it.
