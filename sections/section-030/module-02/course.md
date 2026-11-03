# Manage Resources With The Protection API

A resource server that creates its resources by hand in the Admin Console cannot keep up with an application that creates a shelf, a document or an album for every user. The application needs to register, find, change and delete resources by itself, and it needs to read and revoke the sharing that its users grant. Keycloak gives it one interface for this: the Protection API. This module teaches the calls a resource server makes, and ends with the configuration that lets a policy enforcement point in an API do part of this work.

The Protection API is separate from the Admin REST API. It is addressed to the resource server, not to an administrator. A resource server signs in with its own client credentials, gets a protection API token (PAT) and calls paths under `/realms/inventory/authz/protection`.

Keep one sentence in mind: **the resource server registers what exists, the users decide who may use it, and the Protection API is the channel for both.**

The module has four parts. **Register, Read And Delete Resources** covers the life cycle of one resource. **Find Resources With Query Parameters** searches by name, owner, type, URI and scope. **Read And Revoke Sharing** lists permission tickets and removes one; a graded lab follows it. **Configure The Policy Enforcer** reads the enforcer configuration that Keycloak generates for a client.

## Learning objectives

After this module you can:

- Get a PAT and register, read, update and delete a resource with the Protection API.
- Find resources by name, owner, type, URI or scope.
- List the permission tickets of a resource, and revoke one without deleting the resource.
- Read the `policy-enforcer` configuration of a resource server and say what its main fields do.

## Before you start

You need the basics of Keycloak Authorization Services (resources, scopes, permissions) and the idea of a permission ticket from UMA. Every command runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`protection-demo`**. User-managed access is switched on in the realm `inventory`, which holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` | The resource server, with the client secret `inventory-api-secret` (lab-only). It has the resource `items`, the scopes `view`, `edit` and `delete` and three scope permissions |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
