variable "project" {
  description = "Disposable/sandbox GCP project ID. Do not use a production project."
  type        = string
}

variable "role" {
  description = "Role to grant. Kept low-privilege by default for safety."
  type        = string
  default     = "roles/logging.viewer"
}

variable "existing_member" {
  description = <<-EOT
    The principal that already has `role`, standing in for a grant made
    out-of-band before `02-new-binding` ever runs (another team, the
    console, gcloud, or a different Terraform state).
    Format: "user:you@example.com" or "serviceAccount:sa@project.iam.gserviceaccount.com".
  EOT
  type        = string
}
