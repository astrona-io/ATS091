# Summary

A resource has a name, an optional display name, a type, paths (`uris`), an icon, scopes, an owner, a flag for owner-managed access and free attributes. Only the name is required, and the name is unique in the resource server. Every other field narrows what the resource means, and some of them decide whether a permission finds the resource at all. The Admin REST API reads and updates these fields, and an update changes only the fields you send.

A permission finds resources by name or by type. The type is free text that Keycloak compares exactly, so a resource with a missing or misspelled type is not covered by a permission for that type. The fix for that fault is in the resource: set the type that the permission expects. A new permission for one resource adds a rule that someone must keep, and it hides the real fault.

A resource-based permission names no scopes, so a user who passes its policies receives every scope of the resource. A scope-based permission names the scopes it grants, and every other scope stays denied under the enforcing mode. The safe default for an API with several actions is the scope-based permission, and the safe test is one decision request for each scope, including the scopes that must be denied.

The owner of a resource is always granted, with no policy needed. For a resource created in the Admin Console, the owner is the resource server. For a resource registered for a user through the Protection API, the owner is that user, and `ownerManagedAccess` lets the owner share it. Another user needs a permission or a grant from the owner.

Key facts to remember:

- The type of a resource is compared as exact text.
- A resource-based permission grants all scopes of the resource.
- A scope-based permission grants only the scopes it names.
- The owner of a resource is always granted.

<!-- astrona:playground:destroy -->
