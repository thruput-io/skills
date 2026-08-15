---
name: fast
description: >-
  Google Cloud FAST (Fabric Automation Solution Toolkit) — its stage model, contracts, factories, and
  extension points. Use when working in any repository that vendors FAST stages (fast-org-setup,
  fast-project-factory, fast-networking, or a stage clone), when adding or changing a project, VPC,
  subnet, firewall rule, DNS zone, KMS key or CI/CD wiring in a FAST landing zone, or when deciding
  where a new piece of infrastructure belongs. Read before proposing any change to a FAST repository.
---

# FAST

FAST is two things: a *design* for a production-ready GCP organization, and a Terraform *reference
implementation* of that design, living under `fast/` in
[cloud-foundation-fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric). A
repository that "is a FAST stage" holds a vendored copy of one stage's root module.

## Verify, do not recall

FAST's structure changes between releases, and its details are knowable in seconds. Recalling them is
how wrong architectural claims get made. Every repository pins its release:

```bash
cat fast_version.txt                        # e.g. "# FAST release: v56.1.0"
```

Check the pinned version, not `master`:

```bash
V=v56.1.0
gh api "repos/GoogleCloudPlatform/cloud-foundation-fabric/contents/fast/stages?ref=$V" --jq '.[].name'
gh api "repos/GoogleCloudPlatform/cloud-foundation-fabric/contents/fast/addons?ref=$V" --jq '.[].name'
gh api "repos/GoogleCloudPlatform/cloud-foundation-fabric/contents/fast/stages/<stage>/README.md?ref=$V" \
  -H "Accept: application/vnd.github.raw"
```

Before claiming a stage does or does not support something, read its README and its schema at the
pinned version. Before claiming the live organization matches the repository, query it — committed
`*.auto.tfvars.json` files are **snapshots written by a past apply** and go stale.

## The model: stages are contracts

A stage is a Terraform root module drawn around a **security boundary**, owned by the team
responsible for that class of resource. Stages are contracts: each declares the inputs it needs and
the outputs it publishes, so any stage can be replaced by different code that honours the same
contract.

**Data flows forward only.** No stage depends on outputs produced further down the chain. This is
what keeps stages independently runnable — and it is why "just read it from the later stage" is never
the answer.

### Stage map (v56.x)

| Stage | Owns | Publishes |
|---|---|---|
| `0-org-setup` | organization, hierarchy, tags, custom roles, org policies, automation project, CI/CD workflow rendering, output files | folder ids, project ids, service accounts, tag values, storage buckets, WIF pools/providers |
| `1-vpcsc` | VPC Service Controls perimeters | perimeter names |
| `2-security` | **projects hosting centralized KMS keys**, CAS; extendable to Secret Manager | `kms_keys`, CA ids |
| `2-networking` | host projects, VPCs, subnets, firewall, Cloud NAT, routers, DNS | host project ids and numbers, VPC self links, subnet self links |
| `2-project-factory` | team/application projects and folder hierarchy, via YAML | project ids, service accounts, generated provider files |
| `3-*` | workload stages | varies |
| `addons/` | thin layers on a parent stage | reuse the parent's SAs and state bucket |

A missing capability is often a stage that has not been deployed. If centralized KMS keys or Secret
Manager are absent, the answer is usually `2-security`, not a bespoke workaround.

## The operational rule: author inputs, never edit generated artifacts

| Authored by humans | Generated — never hand-edit |
|---|---|
| dataset YAML (`projects/`, `folders/`, `vpcs/`, `subnets/`, `firewall-rules/`, `dns/`) | `*.auto.tfvars.json` in the outputs bucket |
| `defaults.yaml` for a dataset | `providers.tf` / backend files written for downstream stages and tenants |
| `*.auto.tfvars` committed to select a dataset | rendered CI/CD workflow files |
| your own modules, consumed by a stage | live GCP resources a module manages |

Changing a generated artifact is lost at the next apply and hides the real source. Change the input
that produces it.

Upstream files vendored into the repository (`main.tf`, `factory-*.tf`, `assets/`, sample datasets
carrying a Google copyright header) are replaced on re-vendor. Edits there are lost on upgrade.

## Factories and context interpolation

FAST is factory-driven: a YAML description in, resources out. The dataset is the human surface, and
the dataset path is configurable:

```hcl
factories_config = {
  dataset = "datasets/<name>"          # default: datasets/classic
  paths   = { projects = "projects", folders = "folders", vpcs = "vpcs" }
}
```

Project YAML therefore lives at `datasets/<name>/projects/`, **not** the dataset root. A file on the
wrong path is silently never read — and the resulting empty plan looks identical to success.

Values from preceding stages are referenced by interpolation rather than copied:

```yaml
parent:         $folder_ids:teams/dev
encryption_key: $kms_keys:<project>/<keyring>/<key>
host_project:   $project_ids:net-host-0
member:         $iam_principals:gcp-devops
```

Available context includes `folder_ids`, `project_ids`, `iam_principals`, `tag_values`, `kms_keys`
(from `2-security`), `vpc_sc_perimeters` (from `1-vpcsc`), `storage_buckets`, `service_accounts`,
`workload_identity_pools` and `workload_identity_providers`.

## Where new work belongs — in this order

1. **Dataset YAML**, if the stage's factory covers it. Most work stops here.
2. **An add-on**, if it is a thin platform capability on top of an existing stage. Add-ons reuse the
   parent stage's service accounts and state bucket under a different prefix; register the provider
   file in stage 0's `defaults.yaml` under `output_files.providers`, plus a state folder in the IaC
   project.
3. **Your own module**, versioned in your own repository and instantiated by a stage.
4. **Forking the stage** — last resort. Record the divergence; re-vendoring will overwrite it.

## Tenants are not stages

This distinction is load-bearing, and getting it wrong collapses the model.

| | Stage | Tenant |
|---|---|---|
| Role | platform infrastructure | consumer of the platform |
| Scope | org-wide, privileged | one project |
| Identity | stage automation SAs in the IaC project (`iac-*-cicd-ro` / `-rw`) | its own SAs from the project factory's `automation` block |
| State | its own prefix in the stage state bucket | a **managed folder** in the outputs bucket — not a bucket of its own |
| CI/CD | registered in stage 0's `cicd.yaml`; workflow rendered by stage 0 | consumes generated provider and backend files |

**Do not register a tenant repository in stage 0's `cicd.yaml`.** That mechanism is for stages, and
using it for a tenant grants platform-level identity to a workload repository.

The platform owns the *container* — project, folder placement, tags, billing, APIs, network
attachment, CMEK wiring, state, identity. The tenant owns the *workload* — compute instances,
databases, load balancers, application IAM.

## CI/CD

Stage 0 renders GitHub/GitLab/Okta workflows from `assets/workflow-<provider>.yaml`, driven by
`cicd.yaml`, and writes them to `gs://<outputs_bucket>/workflows/<stage>.yaml`; the downstream
repository pulls its workflow from the bucket on first setup. Pipelines authenticate by Workload
Identity Federation — a read-only service account for `plan`, a read-write one for `apply` — so no
service account keys exist.

FAST does **not** create source repositories. It configures the identity that trusts one. Creating
the repository is a manual act.

## Mistakes to avoid

- Provisioning a per-tenant Terraform state bucket. FAST uses managed folders inside the existing
  outputs bucket, with IAM scoped per project (`bucket_create = false`).
- Hand-writing a tenant's `providers.tf` or `backend.tf`. They are generated; consume them.
- Treating a committed `*.auto.tfvars.json` as current organization state.
- Working around an undeployed stage instead of deploying it.
- Putting a project YAML at the dataset root instead of under `projects/`.
- Assuming a green pipeline proves provenance. `terraform plan` showing no changes proves the
  configuration *matches* reality, not that it *created* it — a hand-built resource that was
  imported looks identical. Provenance lives in Cloud Audit Logs: `CreateProject` records the
  authenticated principal, cannot be disabled, and cannot be edited.

## Related

- `planning` — for producing a plan before changing a landing zone.
