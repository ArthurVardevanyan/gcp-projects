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
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
