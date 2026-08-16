---
name: fast
description: >-
  Orientation and sourced references for Google Cloud FAST (Fabric Automation Solution Toolkit), the
  landing-zone design and Terraform reference implementation in cloud-foundation-fabric. Use when
  working in a repository that vendors a FAST stage, when reading or changing a FAST landing zone,
  or when about to make any claim about how FAST is designed. This is a reference guide, not a
  procedure — its purpose is to get you to the authoritative source quickly rather than to substitute
  for it.
---

# FAST

## The one rule

**Read it at the pinned version. Do not assert it from memory.**

FAST's stage layout has changed across releases, so most published writing about it — including
otherwise good third-party guides — describes a structure that no longer exists. Anything you
"remember" about FAST is likely to be a previous major version.

```bash
cat fast_version.txt        # every vendoring repo pins its release, e.g. "# FAST release: v56.1.0"
```

```bash
V=v56.1.0
gh api "repos/GoogleCloudPlatform/cloud-foundation-fabric/contents/fast/stages?ref=$V" --jq '.[].name'
gh api "repos/GoogleCloudPlatform/cloud-foundation-fabric/contents/fast/stages/<stage>/README.md?ref=$V" \
  -H "Accept: application/vnd.github.raw"
```

Quote URLs containing `?` — the shell will otherwise glob them. For module inputs, outputs and
schemas, use the `fabric-builder` skill's `fabric.py` rather than reading modules by hand; its rule
applies here too: *"Do not invent module inputs or outputs."*

## What FAST is

Two things, and conflating them causes confusion:

> "On the one hand, FAST provides a design of a GCP organization that includes the typical elements
> required by enterprise customers. Secondly, we provide a reference implementation of the FAST
> design using Terraform." — `fast/README.md`

The design is not Terraform-specific: *"in theory, the FAST design can be implemented using any
other tool"* (same source). So a real landing zone is one organisation's **vendored copy of one
implementation at one version, possibly modified** — which is why reading that organisation's
datasets tells you what it actually does, and reading upstream tells you only what it started from.

## Guiding principles

Quoted from `fast/README.md`:

- **Contracts and stages** — *"stages are modeled around the security boundaries that typically
  appear in mature organizations. This arrangement allows delegating ownership of each stage to the
  team responsible for the types of resources it manages."*
- **Security-first design** — *"FAST also aims to minimize the number of permissions granted to
  principals"*, via groups, service accounts, custom roles and IAM Conditions.
- **Extensive use of factories** — *"A resource factory consumes a simple representation of a
  resource (e.g., in YAML) and deploys it."*
- **CI/CD** — Workload Identity Federation, with sample workflow configurations for several
  providers.

And on how the code is meant to read, from the same file: *"Code should avoid magic and be as
explicit as possible… We prefer as little indirection as possible. We favor flat over nested."*

Note also: *"we prefer to provide the basic implementation and encourage users to modify the codebase
if additional (or different) behavior is needed."* Modification is anticipated by design — the cost
is that a modified vendored file is replaced on upgrade.

## The stage model

From `fast/stages/README.md`:

- *"Each of the folders contained here is a separate 'stage', or Terraform root module."*
- *"each stage provides information on its resources to the following stages via predefined
  contracts"*
- *"any stage can be swapped out and replaced by different code as long as it respects the contract"*
- *"the flow of data is always forward looking… so no stage needs to depend on outputs generated
  further down the chain"*

Consequences worth holding onto: a stage is a *root module*, not a repository; contracts are the
interface, so what a stage publishes matters more than how it is implemented; and because data flows
forward only, "read it from the later stage" is never the answer.

Specialised functionality on top of a stage is expressed as an **add-on**: *"additional thin layers
on top of a stage, that reuse its IaC resources and leverage the same IAM configuration: the same
service accounts are used to run the add-on, and state configuration is stored in the same bucket as
their 'parent stage' under a different prefix."* — `fast/addons/README.md`

## How a stage is applied without holding a credential

The stage split is enforced by the pipeline, not merely described by it. A GitHub Actions run
federates an OIDC token into a near-powerless **CI/CD** service account, which impersonates the
**stage** service account, which holds folder-scoped roles narrowed further by IAM Conditions. Read
versus write is decided by whether the pull request merged, so review is what grants write. No
service account key exists anywhere in the path.

Getting this wrong is how roles end up over-granted, so the mechanism, the diagram, the one secret
that is not what it looks like, and a pre-grant checklist are in
[`references/cicd-and-github-actions.md`](references/cicd-and-github-actions.md). Read it before
granting anything to a pipeline identity or adding a stage.

## Reading a specific landing zone

Upstream tells you the design. It does not tell you what a given organisation runs. To learn that:

1. `fast_version.txt` — which release this is vendored from.
2. The dataset directory — the YAML *is* the configuration. `factories_config.dataset` selects which
   directory is read, and `factories_config.paths` where each resource type lives within it.
3. The generated tfvars in the outputs bucket — but treat any committed copy as a **snapshot of a
   past apply**, not current state. Query the live organisation when the answer matters.
4. Diffs against upstream at the pinned ref — anything modified is a local decision, and the reason
   for it is unlikely to be written down.

## Four things commonly got wrong

Verified against `v56.1.0` (commit `8e0826a`). Re-verify at your own pinned release before relying
on any of it.

**VPC Service Controls live in `1-vpcsc`, not in `0-org-setup`.** Stage 0 has no VPC-SC factory —
no access levels, perimeters, ingress or egress policies, restricted services. Its `factories_config.paths`
has nine keys and none of them is VPC-SC. Its only surface is *membership*: a project can be placed
into a perimeter created elsewhere, via `project.vpc_sc.perimeter_name`, using an id supplied through
`context.vpc_sc_perimeters`. If you find perimeter or access-level YAML in a stage 0 dataset, check
whether anything actually reads it.

**Stage-to-repository mapping is not documented.** No upstream file states one repo per stage, or
several stages per repo. The samples and the `fast/extras/0-cicd-github` helper *demonstrate* one
stage per repo — `populate_from` points at a single stage directory — but that is a demonstration,
not a rule. The CI/CD schema requires one `repository.name` per entry and neither requires nor
forbids two entries naming the same repository. Anyone asserting an industry standard here is
asserting something upstream does not say.

**`2-security` is optional, and CMEK does not require it.** It owns Cloud KMS and Certificate
Authority Service, publishing `kms_keys_ids`, `ca_pools` and `tfvars`. The project factory's
`.fast-stage.env` lists it under `FAST_STAGE_OPTIONAL`, not `FAST_STAGE_DEPS`. Its `kms_keys`
variable is optional with an empty default, so key ids for *externally managed* keys can be injected
through `var.context.kms_keys` instead. Upstream documents the mechanism but gives no worked example.

**Tenant CI/CD does not exist.** The project factory generates provider and tfvars files only — no
workflow, no repository creation, and the stage README never mentions repositories. Upstream states
the gap directly: output files *"will be used in future releases to configure project-level CI/CD
from this factory."* Stage 0's CI/CD factory is documented as covering *"this and subsequent stages"*
— stages, not tenants. Its schema is permissive enough that a tenant entry could be hand-added, but
that is not a documented onboarding path.

## The upstream documentation contradicts itself

This is the strongest reason to read schemas and `.tf` rather than READMEs alone. At `v56.1.0`:

- `fast/stages/README.md` says `2-security` *"implements VPC Security Controls via separate
  perimeters"*. It does not — it only consumes optional perimeter ids from `1-vpcsc`. The stage index
  and the stage's own README disagree; trust the stage README.
- `fast/README.md` still describes the pre-v56 split, where "the first stage" is bootstrap and "the
  second" is resource management. Those merged into `0-org-setup`.
- `0-org-setup` and `2-security` READMEs refer to a `data/` folder. The directory is `datasets/`.
- `0-org-setup`'s README names the CI/CD factory file `[dataset]/cicd-workflows.yaml`. The shipped
  files are `cicd.yaml`, and the variable has **no default** — unset means no workflows are rendered.
- Only two of the four shipped datasets carry any CI/CD configuration at all.

## References

**In this skill**
- [`references/cicd-and-github-actions.md`](references/cicd-and-github-actions.md) — how a pipeline
  gets authority: the OIDC → WIF → CI/CD account → stage account chain, why the roles are safe,
  where the workflow file is generated, and what to check before granting anything to a pipeline
  identity

**Primary — authoritative, versioned. Read these before asserting anything.**
- [`fast/README.md`](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/README.md) — design and guiding principles
- [`fast/stages/`](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/stages) — the stage set, with a README per stage
- [`fast/addons/`](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/addons) — the extension mechanism
- Module READMEs and schemas — via `fabric-builder`'s `fabric.py`

**Design rationale — from FAST's own authors**
- [Even FASTer networking](https://medium.com/@sruffilli/google-cloud-platform-even-faster-networking-872e25e70e6b) — Simone Ruffilli, Google, Nov 2025. Why FAST moved to factories: the earlier approach suffered *"poor separation between architectural data and deployment logic"*, and YAML datasets mark *"a separation between the engine and the configurations."* The clearest statement of the principle the whole toolkit rests on. Also gives direct guidance: hierarchical firewall policies at organization or folder level for broad rules, VPC-level rules for specific constraints.

**Design rationale — cited by FAST itself**
- [Resource Factories: A descriptive approach to Terraform](https://medium.com/google-cloud/resource-factories-a-descriptive-approach-to-terraform-581b3ebb59c) — why YAML in, resources out
- [Managing GCP service usage through delegated role grants](https://medium.com/google-cloud/managing-gcp-service-usage-through-delegated-role-grants-a843610f2226) — how stages delegate without over-granting
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) · [IAM Conditions](https://cloud.google.com/iam/docs/conditions-overview) · [Tag-based access control](https://cloud.google.com/iam/docs/tags-access-control)

**Not FAST — a different official landing zone**
- [Enterprise foundations blueprint](https://docs.cloud.google.com/architecture/blueprints/security-foundations) and [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation). Google publishes two landing-zone implementations. Guidance is not interchangeable between them; check which one you are in before applying advice.

## Related

Two first-party skills ship inside `cloud-foundation-fabric` itself, under `skills/`. Prefer them
over anything reconstructed:

- **`fabric-builder`** — generating Terraform against CFF modules. Its `fabric.py` fetches module
  READMEs, variables, outputs and schemas from GitHub, so module interfaces are retrieved rather than
  recalled. Published as `googlecloudplatform/cloud-foundation-fabric@fabric-builder`.
- **`fast/prerequisites`** — step-by-step preparation for running `0-org-setup`.

Nothing in the wider skills ecosystem covers FAST's stage design; the nearest, Google's
`google-cloud-recipe-foundation-builder`, is a different approach to landing zones and does not
mention Fabric, FAST, or Terraform. Check which landing zone you are in before applying its advice.

- `planning` — for producing a plan before changing a landing zone
