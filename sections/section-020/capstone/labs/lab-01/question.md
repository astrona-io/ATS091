# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** policies

## Scenario

In the namespace `policiescapstone-demo`, deleting items on `inventory-api` should be allowed only for members of the group `staff` whose email address ends in `@example.com`. The permission `delete-items` uses one aggregated policy, `staff-with-company-email`, which combines the group policy `staff-members` and the regex policy `company-email`.

Today it decides for the wrong users. The realm has three users:

| User | Group `staff` | Email | Should delete? |
| --- | --- | --- | --- |
| `alice` | yes | `alice@example.com` | yes |
| `bob` | no | `bob@example.com` | no |
| `carol` | yes | `carol@example.org` | no |

## Your task

Find every policy setting that makes `delete-items` decide wrongly for one of these users, and fix it. Several independent settings are wrong. Ask Keycloak for a decision for each user before you change anything, and again after each change.

## Constraints

- **Correct the three policies in place.** Do not delete and recreate `staff-members`, `company-email` or `staff-with-company-email`; the grader checks they are the originals.
- `staff-with-company-email` must keep both of its policies, and `delete-items` must keep using only it.
- Do not change users, their email addresses or the members of `staff`.

## Done when

- `alice` is granted `items#delete`, and `bob` and `carol` are denied it.
- `alice` and `bob` are still granted `items#view`.
- The policies are the originals, and the users are unchanged.
