# This is the bug: Create for google_project_iam_binding is implemented
# identically to Update (resourceIamBindingCreateUpdate in
# google/tpgiamresource/resource_iam_binding.go). It reads the current
# policy, strips whatever binding already exists for `role` (regardless of
# who put it there or whether this config has ever seen it before), and
# replaces it with exactly `members`. No existence check, no diff surfaced
# for what gets dropped.
#
# Applying this config in a project where `role` already has a member (see
# 01-existing-grant) silently removes that member on the very first apply.
resource "google_project_iam_binding" "new" {
  project = var.project
  role    = var.role
  members = [var.new_member]
}
