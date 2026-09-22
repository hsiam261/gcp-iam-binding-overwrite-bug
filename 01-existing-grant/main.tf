# Non-authoritative grant, deliberately independent of 02-new-binding's
# state. This is the "someone/something already granted this" side of the
# bug: it doesn't matter that it's a google_project_iam_member here — a
# manual `gcloud projects add-iam-policy-binding` or a console change
# produces the identical starting condition.
resource "google_project_iam_member" "existing" {
  project = var.project
  role    = var.role
  member  = var.existing_member
}
