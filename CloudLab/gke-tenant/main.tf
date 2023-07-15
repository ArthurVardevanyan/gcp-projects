terraform {
  backend "gcs" {}
}

provider "vault" {}
provider "google" {}

data "vault_generic_secret" "projects" {
  path = "secret/gcp/org/av/projects"
}
data "vault_generic_secret" "gke-tenant" {
  path = "secret/gcp/project/gke-tenant"
}

locals {
  project_id  = data.vault_generic_secret.projects.data["project_id"]
  repo        = data.vault_generic_secret.gke-tenant.data["repo"]
  tenant_user = data.vault_generic_secret.gke-tenant.data["tenant_user"]
  logging_sa  = data.vault_generic_secret.gke-tenant.data["logging_sa"]
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


# resource "google_project_service" "monitoring" {
#   project            = "gke-tenant-${local.project_id}"
#   service            = "monitoring.googleapis.com"
#   disable_on_destroy = false
# }

# resource "google_project_iam_binding" "gke-autopilot" {
#   project = "gke-tenant-${local.project_id}"
#   role    = "roles/logging.bucketWriter"

#   members = ["serviceAccount:${local.logging_sa}"]
# }
