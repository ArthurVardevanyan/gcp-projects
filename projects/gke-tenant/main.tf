terraform {
  backend "gcs" {}
}

provider "vault" {}

data "vault_generic_secret" "gke-tenant" {
  path = "secret/gcp/project/gke-tenant"
}

locals {
  project_id  = data.vault_generic_secret.gke-tenant.data["project_id"]
  repo        = data.vault_generic_secret.gke-tenant.data["repo"]
  gke_project = data.vault_generic_secret.gke-tenant.data["gke_project"]
}

provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_project_service" "api" {
  project = local.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_cloudbuild_trigger" "manual-trigger" {
  name = "manual-build"

  source_to_build {
    uri       = local.repo
    ref       = "refs/heads/production"
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = "projects/GKE-Tenant/cloudbuild.yaml"
    uri       = local.repo
    revision  = "refs/heads/production"
    repo_type = "GITHUB"
  }

  substitutions = {
    _PROJECT = local.gke_project
  }
}
