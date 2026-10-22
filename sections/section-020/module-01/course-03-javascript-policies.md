# JavaScript Policies

Sometimes no built-in policy type fits a rule. A rule might compare two attributes with each other, or look at a value in the request that no other policy reads. For those cases Keycloak has JavaScript policies: a short script that runs inside Keycloak and grants or denies. They are also the one policy type you cannot create from the Admin Console or the Admin REST API, and this part explains why and how they are deployed instead. This page has no hands-on steps; it describes a deployment that needs a build step on the server.

## What a JavaScript policy is

A JavaScript policy is a policy whose logic is a script. Keycloak runs the script for each evaluation and passes it an object, `$evaluation`, from the Evaluation API. The script reads the context from it (the identity of the user, the attributes of the request, the permission being evaluated) and calls `$evaluation.grant()` to grant. If the script does not grant, the policy denies.

A script that grants only to users with the attribute `department` set to `logistics` looks like this:

```javascript
var context = $evaluation.getContext();
var identity = context.getIdentity();
var attributes = identity.getAttributes();

if (attributes.containsValue('department', 'logistics')) {
  $evaluation.grant();
}
```

The script runs inside the Keycloak server with access to the evaluation context. That power is the reason for the deployment rules below.

## Why the Admin Console cannot upload one

By default, JavaScript policies cannot be uploaded to the server. An administrator who could upload a script through the Admin Console or the REST API could run code inside Keycloak. Keycloak therefore only accepts scripts that someone deployed on the server itself, in the same way as any other extension.

## How a JavaScript policy is deployed

A script is deployed in a JAR file, which is a ZIP file with the extension `.jar`. The JAR holds the scripts and a descriptor, `META-INF/keycloak-scripts.json`, that lists them:

For example, a JAR named `inventory-policies.jar` holds two files: `META-INF/keycloak-scripts.json` and, at the top level, `logistics-only.js`.

The descriptor has one array per script type: `authenticators`, `policies`, `mappers` and `saml-mappers`. Each entry has a `name`, which the Admin Console shows; a `fileName`, which is mandatory and must match a file in the JAR; and an optional `description`:

```json
{
  "policies": [
    {
      "name": "Logistics Only",
      "fileName": "logistics-only.js",
      "description": "Grants to users whose department attribute is logistics"
    }
  ]
}
```

The deployment then takes three steps, all on the server:

1. Copy the JAR into the `providers/` directory of the Keycloak installation, which is `/opt/keycloak/providers/` in the container image.
2. Run `kc.sh build`, because providers are part of the optimized server. In a container, this happens in the image build.
3. Start Keycloak with the `scripts` feature switched on. The Server Developer Guide lists JavaScript policies among the script types of this feature, and the feature is a preview feature, off by default: start the server with `--features=scripts` (or `--features=preview`).

After that, the policy appears in the list of policy types of every resource server, under the name from the descriptor. An administrator can then create policies of that type and use them in permissions like any other policy. Nobody can change the script from the Admin Console; a new version means a new JAR and a new deployment.

## When to use one

A JavaScript policy is the last resort, not the first. It needs a custom image, a preview feature and code that someone must review and maintain. Most rules that look like they need a script fit a combination of built-in policies: a regex policy on a claim, a group policy, a time policy, all joined by an aggregated policy. Write the script only when that combination cannot express the rule.

You now know what a JavaScript policy is, why Keycloak refuses to upload one, and the exact JAR layout and steps that deploy one. The question left is the other side of every policy: the request an API sends to ask for a decision, and the different answers it can ask for.

## Common pitfalls

> [!WARNING]
> - **Looking for an upload button.** There is none by default. A JavaScript policy only exists after a JAR is deployed and the server is rebuilt.
> - **Forgetting `fileName`.** It is mandatory and must name a file inside the JAR, or the policy does not appear.
> - **Forgetting `kc.sh build` or the `scripts` feature.** Without them, the JAR is copied but the policy type never appears.
> - **Writing a script for a rule built-in policies can express.** The script has to be reviewed, built and deployed for every change; a regex or aggregated policy does not.
