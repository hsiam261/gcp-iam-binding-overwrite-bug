variable "project" {
  description = "Same sandbox GCP project ID as used in 01-existing-grant."
  type        = string
}

variable "role" {
  description = "Same role as used in 01-existing-grant. This is what makes Create collide."
  type        = string
  default     = "roles/logging.viewer"
}

variable "new_member" {
  description = <<-EOT
    The only principal this config knows about. Must be DIFFERENT from
    01-existing-grant's `existing_member` — that's what makes the overwrite
    visible: after apply, existing_member is gone and only new_member
    remains, with no diff or warning ever shown for the removal.
    Format: "user:you@example.com" or "serviceAccount:sa@project.iam.gserviceaccount.com".
  EOT
  type        = string
}
