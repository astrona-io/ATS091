# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS091 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Fine-Grained Authorization Services** domain of
  the **Keycloak** training path (`ATP018`). It is 15% of the path. There is
  no official Keycloak certification exam; the path's domains and weights are
  Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** making Keycloak decide who may do what on
  which resource, and proving the decision. The student must *do* things
  (switch on authorization for a client, create scopes, resources, policies
  and permissions with `kcadm.sh`, ask Keycloak for a decision over REST,
  read a requesting party token, run an API that enforces decisions). Every
  explanation should lead to a command they can run, and every fix should be
  proved with a decision request (or an API request) that answered wrongly
  before and answers correctly after.
- **The three topics:** the authorization model (resource servers,
  resources, scopes, permissions, decision strategies, the enforcement
  mode), policies (role, user, group, client, regex, time, aggregated and
  JavaScript policies, and asking for a decision), and User-Managed Access
  (UMA) 2.0 with a policy enforcement point in an API.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | The Authorization Services Model | Resource servers, resources, scopes, permissions |
  | 020 | Policies And Decisions | Policy types and decision requests |
  | 030 | UMA 2.0 And Policy Enforcement | UMA, the RPT and an enforcing API |

- **The version:** everything is written for **Keycloak 26.8.1**, image
  `quay.io/keycloak/keycloak:26.8.1`, on a single-node `kind` cluster. Do not
  teach fields, flags or output from other versions without saying so. Pin
  every image tag; never use `latest`.
- **The main sources:** the Authorization Services Guide,
  <https://www.keycloak.org/docs/latest/authorization_services/index.html>,
  and the Server Administration Guide. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Things most likely to need a fix on the first run: whether the Admin REST
  API accepts scope **names** inside a resource's `scopes` list, the exact
  field names `kcadm get ... --fields` returns for resources (`_id`) and
  policies (`id`), and the names of the default objects Keycloak creates when
  authorization is switched on.
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, UMA's, OAuth's and Kubernetes' own words. Define
each one in plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Authorization Services | The part of Keycloak that stores resources, scopes, policies and permissions for a client and answers "may this user do this" |
| Resource server | A client with authorization switched on (`authorizationServicesEnabled`); it owns the resources and the rules that protect them |
| Resource | A thing to protect, with a name, an optional type and URIs, for example `items` with `/items/*` |
| Scope | An action on a resource, for example `view`, `edit` or `delete` |
| Policy | A rule that grants or denies on its own, for example "the user has the role `inventory-manager`"; it protects nothing until a permission uses it |
| Permission | Joins resources or scopes to policies: "to `delete` an `items` resource, these policies must agree" |
| Resource-based / scope-based permission | Protects whole resources / protects chosen scopes |
| Decision strategy | How the results of several policies (or permissions) combine: `UNANIMOUS` (all must grant, the default), `AFFIRMATIVE` (one is enough), `CONSENSUS` (more grants than denials; a tie denies) |
| Logic | `POSITIVE` keeps a policy's result, `NEGATIVE` turns it around |
| Policy enforcement mode | `ENFORCING` (the default; a request with no matching permission is denied), `PERMISSIVE` (a request with no matching permission is allowed), `DISABLED` (everything is allowed) |
| Policy enforcement point (PEP) | The code in an API that asks Keycloak for a decision and lets a request through or refuses it |
| RBAC / ABAC / PBAC | Role-based, attribute-based and policy-based access control |
| UMA 2.0 | User-Managed Access, an OAuth 2.0 extension where a resource server hands out permission tickets and the client exchanges them for an RPT |
| Permission ticket | An opaque value a resource server gets from Keycloak that names the resources and scopes a request needs |
| RPT | Requesting party token: an access token that carries the granted permissions in its `authorization.permissions` claim |
| PAT | Protection API token: a token with the `uma_protection` scope that a resource server uses to call the Protection API |
| `uma-ticket` grant | `grant_type=urn:ietf:params:oauth:grant-type:uma-ticket` at the token endpoint; returns an RPT, a decision or a list of permissions |

Do not invent friendly names for these. Never call a policy a "rule book" or
a permission a "key".

### The example workloads

Every module deploys the same setup into its own namespace (`model-demo`,
`policies-demo`, `uma-demo`; capstones use `modelcapstone-demo`,
`policiescapstone-demo` and `umacapstone-demo`).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak` (Deployment and Service) | `quay.io/keycloak/keycloak:26.8.1` | One Keycloak pod in development mode. Service port `8080` (`http`) and `9000` (`management`) |
| `keycloak-admin` (Secret) | | Bootstrap administrator: user `admin`, password `admin`. Lab-only credentials; say so when a page uses them |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Every token and decision request is sent from here |
| `inventory-api` (Deployment, Service, ConfigMap `inventory-api-code`) | `node:22-alpine` | Section 030 only. A small HTTP API on port `3000` that is a policy enforcement point: `GET`, `POST` and `DELETE` on `/items` map to the scopes `view`, `edit` and `delete` |

Inside Keycloak, every module uses the same names:

| Keycloak name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | Password `alice-password`, email `alice@example.com`, realm roles `inventory-viewer` and `inventory-manager`, member of the group `staff` |
| user `bob` | Password `bob-password`, email `bob@example.com`, realm role `inventory-viewer` only, in no group |
| user `carol` | Section 020 capstone only. Password `carol-password`, email `carol@example.org`, member of `staff` |
| client `inventory-cli` | Public client with **Direct access grants** on; the reader and the graders get user tokens with it |
| client `inventory-api` | Confidential client with service accounts on and client secret `inventory-api-secret`; the resource server |
| scopes `view`, `edit`, `delete` and resource `items` (URIs `/items`, `/items/*`) | The protected model on `inventory-api` |
| policies `inventory-viewers`, `inventory-managers` | Role policies on `inventory-viewer` and `inventory-manager` |
| permissions `view-items`, `edit-items`, `delete-items` | Scope permissions on `items` |

The password grant is used **only** so a grader and the reader can get a user
token from a terminal. Say every time it is used that OAuth 2.1 drops it and a
real application uses the authorization code flow.

### Environment facts the text must respect

- **Keycloak runs as plain Kubernetes manifests** in development mode
  (`start-dev`), the same canonical manifest as ATS088 with the namespace
  changed.
- **The helpers.** Pages and scripts use the same shell functions, defined
  once per page that needs them:

  ```sh
  NAMESPACE=model-demo
  kcadm() {
    kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
      /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
  }
  kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
  API_ID=$(kcadm get clients -r inventory -q clientId=inventory-api --fields id --format csv --noquotes)
  AUTHZ="clients/$API_ID/authz/resource-server"
  authz_id() {   # authz_id resource|scope|policy NAME -> the object's id
    local field=id
    [ "$1" = resource ] && field=_id
    kcadm get "$AUTHZ/$1/search" -r inventory -q name="$2" --fields "$field" --format csv --noquotes
  }
  user_token() {   # user_token alice -> an access token for alice
    kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
      "curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
        -d grant_type=password -d client_id=inventory-cli \
        -d username=$1 -d password=$1-password | jq -r .access_token"
  }
  decision() {   # decision alice items#delete -> 200 (granted) or 403 (denied)
    kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s -o /dev/null -w '%{http_code}\n' \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -H "Authorization: Bearer $(user_token "$1")" \
      -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
      -d audience=inventory-api -d permission="$2" -d response_mode=decision
  }
  ```

  Always pass ids, not names, when one Keycloak object refers to another
  (roles in a role policy, groups in a group policy, resources, scopes and
  policies in a permission); `authz_id` and `kcadm get roles/<name>` give
  them.
- **Seen on a live run (2026-10-23):** a resource's `scopes` list must name
  each scope (`{"name":"view"}`, or `id` together with `name`). Scope
  objects with only an `id` are collapsed into one: Keycloak 26.8.1 stores
  just the first scope, and a later scope permission on another scope fails
  with `Scope [edit] is not associated with any of the resources set to the
  permission`. Permissions still take plain id strings in `scopes`.
- **Keycloak 26.8.1 facts (from the documentation, not yet seen on a run):**
  - Authorization needs a confidential client (`publicClient=false`) with
    service accounts on; then `authorizationServicesEnabled=true`.
  - The Admin REST paths live under
    `clients/<client-id>/authz/resource-server/`: `scope`, `resource`,
    `policy/<type>` (`role`, `user`, `group`, `client`, `client-scope`,
    `time`, `regex`, `aggregate`, `js`), `permission/resource`,
    `permission/scope`, and `search` under `resource`, `scope` and `policy`.
  - Policy enforcement mode default `ENFORCING`; decision strategy default
    `UNANIMOUS`; logic default `POSITIVE`.
  - A time policy's conditions (start, expire, day of month, month, year,
    hour, minute) must **all** hold. Hours follow the server's clock, which is
    UTC in the container.
  - `uma-ticket` parameters: `ticket`, `claim_token`, `claim_token_format`,
    `rpt`, `permission` (`RESOURCE#SCOPE`, repeatable, needs `audience`),
    `audience`, `response_include_resource_name`,
    `response_permissions_limit`, `submit_request`, `response_mode`
    (`decision` returns `{"result": true}`, `permissions` returns a list of
    `rsid` and `scopes`). A denial is HTTP `403` with `"error":
    "access_denied"`.
  - The RPT is returned in `access_token`; its permissions are in
    `authorization.permissions`.
  - UMA: the resource server answers `401` with a `WWW-Authenticate: UMA`
    header (`realm`, `as_uri`, `ticket`). It creates tickets at
    `/realms/<realm>/authz/protection/permission` with a PAT. Keycloak gives
    each resource server's service account the `uma_protection` role.
  - User-Managed Access is a realm setting (Realm Settings, **User-managed
    access**, `userManagedAccessAllowed`). Owners manage sharing in the Account
    Console under **My Resources**. Resources need `ownerManagedAccess: true`.
  - **JavaScript policies cannot be uploaded** through the Admin Console or
    the REST API by default. They are deployed as a JAR in `providers/`
    with `META-INF/keycloak-scripts.json` (a `policies` array of `name`,
    `fileName`, `description`), followed by `kc.sh build`. The Server
    Developer Guide lists JavaScript policies among the script types of the
    `scripts` feature, which is **preview** and off by default
    (`--features=scripts`). This course explains JavaScript policies in prose
    only; **no graded lab uses one**, because a lab cannot build a JAR.
- **Time-dependent results.** A time policy's result depends on the clock, so
  graders never grade a decision that a time policy can flip. They grade the
  time policy's settings plus decisions that are the same at every hour (for
  example a user that another policy always denies).
- **Many environments start broken on purpose.** A lab seeds the fault after
  Keycloak is up. The fault is the material. Never "fix" it in the bootstrap.
- **Keycloak is slow to start.** Allow up to five minutes for the first
  rollout.
- **The proof is a decision.** A fix is proven with `decision <user>
  items#<scope>` returning `200` or `403` as the task says, or, in section
  030, with a request to `inventory-api` from `tester`.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds `config.yaml`, `README.md`, `prerequisites.md`,
`question.md`, `solution.md`, `bootstrap/01-deploy-keycloak.sh` (Keycloak plus
the realm, users and clients), `bootstrap/02-seed-state.sh` (the starting
authorization model, broken on purpose where the task says so),
`manifests/lab-start.yaml`, `solution/apply.sh` (reference end state, applied
only by `astrona test`), `testing/wait-for-keycloak.sh` and
`validation/validate-*.sh`.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS091`, domain
`Fine-Grained Authorization Services`, weight `15`) and one entry per section
under `modules:`. Every `type: lab` entry carries, in order: `title`, `path`,
`difficulty`, `estimated_duration`, `topic`, `task_kind`, `tags`,
`learning_goals`, `resources`.

- `topic`: exactly one of `authorization-model`, `policies`, `decisions`,
  `uma`, `enforcement`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below.
- `resources`: 1 to 4 pages on `keycloak.org`, each with a `name` and a `url`.
  The only place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Model: `resource-server`, `resources`, `scopes`, `scope-permission`,
  `resource-permission`, `decision-strategy`, `enforcement-mode`
- Policies: `role-policy`, `user-policy`, `group-policy`, `client-policy`,
  `regex-policy`, `time-policy`, `aggregated-policy`, `javascript-policy`,
  `policy-logic`
- Decisions and UMA: `uma-ticket-grant`, `decision-request`, `rpt`,
  `permission-ticket`, `pat`, `user-managed-access`
- Enforcement and tools: `policy-enforcement-point`, `kcadm`,
  `admin-rest-api`, `rbac`, `abac`, `pbac`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-010/module-01/playground
astrona destroy ats-091-playground-010-01

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS091.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-091-lab-010-01

# Authors
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-091-playground-<section>-<module>`, a module lab
is `ats-091-lab-<section>-<module>` and a capstone is
`ats-091-capstone-<section>`; keep those names. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**: real decision requests, and in section 030 real
requests to `inventory-api`. Graders also reject the plausible but wrong fix
(switching the enforcement mode to `PERMISSIVE` or `DISABLED`, deleting a
permission instead of correcting it, removing a user's role to make a
decision come out right, changing the API's code instead of the model).

Test clusters on the maintainer's machine: one at a time.

### Where to find trusted sources

- [Authorization Services Guide](https://www.keycloak.org/docs/latest/authorization_services/index.html)
  (resource servers, resources, scopes, policies, permissions, the evaluation
  tool, obtaining permissions, UMA, the Protection API, policy enforcers)
- [Server Developer Guide: JavaScript providers](https://www.keycloak.org/docs/latest/server_development/index.html#_script_providers)
- [Server Administration Guide: Admin CLI](https://www.keycloak.org/docs/latest/server_admin/index.html#admin-cli)
- [UMA 2.0 Grant for OAuth 2.0 Authorization](https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
