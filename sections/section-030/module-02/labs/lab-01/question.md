# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** uma

## Scenario

The resource server `inventory-api` in the namespace `protection-demo` stores shelves and notes for its users. `alice` owns the resource `alice-shelf` and shared it with `bob` for the scopes `view` and `edit`. She now wants `bob` to read the shelf but not change it. She also asks the application to register a resource for her notes.

## Your task

1. Register a resource named `alice-notes` with the Protection API. It has the scope `view`, `alice` is its owner and `ownerManagedAccess` is `true`.
2. Reduce the sharing of `alice-shelf` so that `bob` can only use the scope `view`.
3. Prove both changes with decision requests.

## Constraints

- Use the Protection API with a protection API token of `inventory-api`.
- Do not delete `alice-shelf` and do not change the permissions in the Admin Console.
- Do not change the roles of any user.

## Done when

- `alice-notes` exists, `alice` is granted `alice-notes#view` and `bob` is denied it.
- `bob` is granted `alice-shelf#view` and denied `alice-shelf#edit`.
- The only granted ticket left on `alice-shelf` is the one for `view`.
