# Know The Architecture And Manage Resource Server Settings

The inventory API now has a working model, and the model lives in Keycloak. A team that runs this for real needs more than the first model. They need to know which component does what, where each setting of the resource server lives, how to read everything with scripts instead of the Admin Console, and how to move the whole model from one environment to another. This module covers those four things.

The model is the same as before: the resource server `inventory-api` owns the resource `items`, two role policies and three scope permissions. What changes is the view. The module reads the same objects from the architecture side, from the settings side, from the Admin REST API side and from the export file side.

Keep one sentence in mind: **everything the Admin Console shows is one call to the Admin REST API, and the whole model fits in one JSON file.**

The module has five parts. **The Four Components Of The Architecture** names the policy administration point, the policy decision point, the policy enforcement point and the policy information point, and shows which Keycloak part plays each one. **Resource Server Settings** covers the enforcement mode, the decision strategy and remote resource management. **The Admin Console And The Admin REST API** maps every tab of the Authorization page to a call you can script. **Export And Read The Settings File** shows what the exported JSON contains and how to query it. **Import Settings Into Another Resource Server** moves the model to a second resource server; a graded lab follows it.

## Learning objectives

After this module you can:

- Name the four components of the authorization architecture and say which Keycloak part plays each.
- Read and change the three resource server settings with `kcadm.sh`.
- Find every object of a resource server with the Admin REST API, and find which permissions use a policy.
- Export the settings of a resource server and read the objects in the file.
- Import the settings file into a second resource server and prove that it decides the same way.

## Before you start

You need Kubernetes basics (`kubectl exec`), `curl` and the basics of Keycloak Authorization Services: scopes, resources, policies, permissions and the `uma-ticket` decision request. Every command runs against the playground cluster.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode, in the namespace **`settings-demo`**. The realm `inventory` holds:

| Name | What it is |
| --- | --- |
| `alice` | Roles `inventory-viewer` and `inventory-manager`, password `alice-password` |
| `bob` | Role `inventory-viewer`, password `bob-password` |
| `inventory-cli` | Public client; you use it to get tokens for `alice` and `bob` |
| `inventory-api` | The resource server: the resource `items` with the scopes `view`, `edit` and `delete`, the role policies `inventory-viewers` and `inventory-managers`, and the scope permissions `view-items`, `edit-items` and `delete-items` |
| `inventory-api-v2` | A second confidential client with authorization switched on and no model of its own yet |
| `tester` | A pod with `curl` and `jq` |

The `master` realm administrator is `admin` with the password `admin`. These are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
