# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** decisions

## Scenario

`inventory-api` in the namespace `evaluate-demo` lets managers delete items, but only managers who belong to the staff group. `dana` has the role `inventory-manager` and complains that a request to delete items is denied. Nobody can say which rule stops her.

## Your task

1. Use the evaluation tool of the resource server `inventory-api` to find the policy that denies `dana` the scope `delete` on `items`.
2. Fix the cause so that `dana` can delete items.
3. Prove the fix with a decision request for `dana`, and prove that `bob` is still denied.

## Constraints

- Do not change the permissions, the policies, the policy logic, the decision strategies or the enforcement mode.
- Do not remove any role from any user.
- Do not use `PERMISSIVE` or `DISABLED`.

## Done when

- `dana` is granted `items#delete`, and `alice` is still granted it.
- `bob` is denied `items#delete`.
- `delete-items` still uses only `staff-managers`, which still holds `inventory-managers` and `staff-only`.
- The decisions for `view` and `edit` are unchanged.
