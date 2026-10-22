# Welcome To The Course

This course trains you for the **Fine-Grained Authorization Services** part of the Astrona **Keycloak** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, `kubectl exec` and `kubectl logs`. You know the basics of Keycloak: a realm holds users and clients, a client gets tokens from the token endpoint, and a token carries the user's roles. You can send a request with `curl` and read JSON. You do not need to know Keycloak Authorization Services yet. Each new idea is explained the first time it appears.

## What you can do at the end

Authorization is about decisions, so this course does not ask you to remember words. It asks you to build rules in Keycloak, ask Keycloak for decisions, and prove that the right people get in and the wrong people do not. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **the authorization model**. You will learn to:

- Explain what role-based checks in an API cannot express, and what policy-based access control adds.
- Turn a client into a resource server, and create its scopes, resources, policies and permissions.
- Predict the result of decision strategies and of the policy enforcement mode.

The second topic is **policies and decisions**. You will learn to:

- Write role, user, group, client, regex, time and aggregated policies, and use negative logic safely.
- Explain how JavaScript policies are deployed, and why they cannot be uploaded.
- Ask Keycloak for a decision, a list of permissions or a requesting party token (RPT), and read each answer.

The third topic is **User-Managed Access (UMA) 2.0 and policy enforcement**. You will learn to:

- Walk through the UMA flow with a protection API token, a permission ticket and an RPT.
- Let a user own a resource and share it with another user.
- Read a policy enforcement point in an API, and trace a wrong answer to the API or to the model.

Everything is written for **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's, OAuth's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **resource server** is a client with authorization switched on; it owns the things to protect and the rules that protect them. Four kinds of object live in it:

| Object | What it is |
| --- | --- |
| Scope | An action, such as `view`, `edit` or `delete` |
| Resource | A thing to protect, such as `items`, with the scopes that apply to it |
| Policy | A rule that grants or denies on its own, such as "has the role `inventory-manager`" |
| Permission | Joins policies to resources or scopes; only a permission protects anything |

A **decision** is Keycloak's answer to "may this user use this scope on this resource": granted (`200`) or denied (`403`). An API asks for it with the **`uma-ticket` grant** at the token endpoint.

## The example setup in your playground

Every playground and lab runs the same small setup. One Keycloak pod holds the realm `inventory`. Two users come back on every page: `alice`, who may view, edit and delete items, and `bob`, who may only view them. The client `inventory-api` is the resource server, with the resource `items` and the scopes `view`, `edit` and `delete`. You send token and decision requests from the `tester` pod, a client with `curl` and `jq`. In the last section, a small HTTP API, also called `inventory-api`, asks Keycloak for a decision on every request.

Each module puts this setup in its own namespace, for example `model-demo` or `uma-demo`, so the pages always tell you the namespace to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with the model, then the rules inside it, and ends with the API that enforces them.

| Section | What it covers |
| --- | --- |
| 010 | The Authorization Services Model |
| 020 | Policies And Decisions |
| 030 | UMA 2.0 And Policy Enforcement |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
