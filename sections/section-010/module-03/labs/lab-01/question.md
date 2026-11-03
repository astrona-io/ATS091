# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** authorization-model

## Scenario

The resource server `inventory-api` in the namespace `resources-demo` stores shelves. The permission `view-shelves` lets users with the role `inventory-viewer` use every resource of the shelf type. The user `bob` has that role. He can use `shelf-a` and `shelf-b`, but the application registered a third shelf, `shelf-c`, and `bob` is denied it.

## Your task

1. Find out why `bob` is denied `shelf-c` although `view-shelves` exists.
2. Fix the cause so that `bob` is granted `shelf-c`.
3. Prove it with decision requests for `bob`.

## Constraints

- Do not create, delete or change any permission or policy.
- Do not change the roles of any user.
- Do not set the enforcement mode to `PERMISSIVE` or `DISABLED`.
- `bob` must still be denied the resource `vault`.

## Done when

- `bob` is granted `shelf-a`, `shelf-b` and `shelf-c`.
- `bob` is denied `vault`.
- The permissions are the original four.
