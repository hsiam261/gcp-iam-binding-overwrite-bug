terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

# Application Default Credentials: run `gcloud auth application-default
# login` before `terraform init`/`apply`. No credentials are configured here
# on purpose.
provider "google" {
  project = var.project
}
