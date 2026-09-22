# gcp-iam-binding-overwrite-bug

Minimal repro for: `google_project_iam_binding`'s `Create` silently **overwrites**
any pre-existing members already bound to the same role, instead of failing or
merging. No diff is ever shown for what gets removed — `terraform apply`
reports a clean success.

This is the exact failure mode discussed in
[hashicorp/terraform-provider-google#2379](https://github.com/hashicorp/terraform-provider-google/issues/2379)
and [#8354](https://github.com/hashicorp/terraform-provider-google/issues/8354):
a role already has a member (bound by another team, another Terraform state,
the console, or `gcloud`), and the first time `google_project_iam_binding`
touches that role, it wipes out whoever was already there.

## What this simulates

Two **independent** Terraform root modules / states, representing two
operators who don't know about each other — which is how this bug actually
bites people in practice:

- `01-existing-grant/` — a `google_project_iam_member` grant for a role,
  standing in for "whatever put a member on this role before Team B ever
  touched it" (could just as easily be a manual `gcloud` grant, a console
  change, or a completely different Terraform state).
- `02-new-binding/` — a `google_project_iam_binding` for the **same role**,
  applied by someone who has no idea `01-existing-grant` exists. Its `Create`
  is the exact code path in
  [`google/tpgiamresource/resource_iam_binding.go`](https://github.com/hashicorp/terraform-provider-google/blob/main/google/tpgiamresource/resource_iam_binding.go)
  that unconditionally replaces the role's member list.

## Prerequisites

- **A disposable/sandbox GCP project.** This will genuinely modify real IAM
  policy on whatever project you point it at. Do not run this against a
  production project.
- `gcloud auth application-default login` run beforehand — both configs use
  Application Default Credentials (no service account key, no explicit
  `credentials` block in the provider).
- The identity behind those credentials needs
  `roles/resourcemanager.projectIamAdmin` (or broader) on the target project.
- Terraform installed.

## Steps

```sh
# 1. Simulate the pre-existing grant.
cd 01-existing-grant
cat > terraform.tfvars <<'EOF'
project         = "your-sandbox-project-id"
existing_member = "user:someone@example.com"
EOF
# existing_member should be a real principal you control (e.g. a second
# Google account or a service account), distinct from new_member in step 3.
terraform init
terraform apply

# 2. Confirm the grant is live.
gcloud projects get-iam-policy "$PROJECT" \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/logging.viewer" \
  --format="value(bindings.members)"
# -> shows existing_member

# 3. Someone else, unaware of step 1, adopts google_project_iam_binding
#    for the same role.
cd ../02-new-binding
cat > terraform.tfvars <<'EOF'
project    = "your-sandbox-project-id"
new_member = "user:you@example.com"
EOF
# SAME project and role as step 1, but new_member must be DIFFERENT from
# existing_member above.
terraform init
terraform apply
# -> reports success. No warning, no diff, no mention that another
#    principal is about to be removed.

# 4. Re-check the policy.
gcloud projects get-iam-policy "$PROJECT" \
  --flatten="bindings[].members" \
  --filter="bindings.role:roles/logging.viewer" \
  --format="value(bindings.members)"
# -> existing_member is GONE. Only new_member remains.
```

Step 3's `apply` output never mentions `existing_member` at all — the removal
is invisible in the plan and the apply, which is the whole bug: the first
person to find out is whoever notices `existing_member` lost access, usually
much later and for an unrelated-looking reason.

## Cleanup

```sh
cd 02-new-binding && terraform destroy
cd ../01-existing-grant && terraform destroy
```

## Where the behavior lives in the provider

`resourceIamBindingCreateUpdate` in
`google/tpgiamresource/resource_iam_binding.go` is used for *both* `Create`
and `Update` — it always strips whatever binding currently exists for the
role/condition and replaces it with what's in `members`, with no check for
whether something was already there. See the sibling
`terraform-provider-google` checkout for the full discussion and a candidate
fix (`Create`-only existence check requiring `terraform import` instead of a
silent overwrite).
