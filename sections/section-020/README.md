# Section 020: Policies And Decisions

A role policy answers one question: does the user have this role? Most access rules need more. They depend on a group, on an attribute such as the email address, on the client that asks, or on the time of day, and often on several of these at once. A rule that lives in an API's code is hard to read and hard to audit. A rule that lives in a Keycloak policy has a name, a type and settings anyone can list.

This section covers every policy type Keycloak offers, how to combine policies, and the request an API sends to get a decision. It ends with JavaScript policies, the one type you cannot create from the Admin Console, and why.

**Topic covered:** policies and decisions

## What you will learn

- Role, user, group, client and regex policies: what each one checks and which input it reads.
- Positive and negative policy logic, and how a negative policy can grant to the wrong people.
- Time policies: the fields they use and why their result depends on the server's clock.
- Aggregated policies: combining other policies with a decision strategy.
- How JavaScript policies are packaged and deployed, and why the Admin Console cannot upload them.
- The `uma-ticket` grant in depth: `response_mode=decision`, `response_mode=permissions`, and the requesting party token (RPT) with its `authorization` claim.

## The learning path

The section has one module. It has a landing page, four short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, and the landing page starts it for you.

### 1. Write Policies That Decide Access

The playground holds Keycloak with the realm `inventory` and a working, role-based authorization model on the client `inventory-api`: the resource `items` with the scopes `view`, `edit` and `delete`, two role policies and three scope permissions.

1. Role, User, Group, Client And Regex Policies
2. Time Policies And Aggregated Policies, followed by the lab **Allow Deletes Only For Staff In Business Hours**
3. JavaScript Policies
4. Asking Keycloak For A Decision
5. Summary

## Section capstone: Fix A Policy Set That Decides For The Wrong Users

The capstone is one graded scenario that uses the whole module. Deleting items should be allowed only for members of the group `staff` whose email address belongs to the company. Today the wrong people may delete, and the right person may not. Three independent policy settings are wrong. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-091-capstone-020
```
