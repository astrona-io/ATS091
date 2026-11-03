# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** policies

## Scenario

The resource server `inventory-api` in the namespace `clients-demo` has a resource `invoices` with the scope `export`. No permission protects it yet. Only exports that come from the client `billing-cli` are allowed. The user `alice` signs in with both `billing-cli` and `inventory-cli`.

## Your task

1. Create a client policy that allows only the client `billing-cli`.
2. Create a scope permission for `invoices` and the scope `export` that uses the policy.
3. Prove it with decision requests for `alice` from both clients.

## Constraints

- Use a client policy, not a role policy or a user policy.
- Do not change the existing permissions `view-items`, `edit-items` and `delete-items`.
- Do not change the roles of any user.
- Do not set the enforcement mode to `PERMISSIVE` or `DISABLED`.

## Done when

- `alice` is granted `invoices#export` from `billing-cli`.
- `alice` is denied `invoices#export` from `inventory-cli`.
- A client policy that lists `billing-cli` exists and the original permissions still decide the same way.
