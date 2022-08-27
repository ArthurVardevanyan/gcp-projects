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
  gke_sa      = data.vault_generic_secret.gke-tenant.data["gke_sa"]
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_project_service" "artifactregistry" {
  project            = local.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "containers" {
  location      = "us-central1"
  repository_id = "containers"
  format        = "DOCKER"
}

resource "google_project_iam_binding" "artifactregistry_reader" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${local.gke_sa}"
  ]
}


resource "google_project_service" "cloudbuild" {
  project            = local.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
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
