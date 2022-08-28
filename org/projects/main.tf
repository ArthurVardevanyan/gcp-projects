terraform {
  backend "gcs" {}
}

provider "google" {}

provider "vault" {}

data "vault_generic_secret" "projects" {
  path = "secret/gcp/org/av/projects"
}

locals {
  project_id       = data.vault_generic_secret.projects.data["project_id"]
  org_id           = data.vault_generic_secret.projects.data["org_id"]
  billing_account  = data.vault_generic_secret.projects.data["billing_account"]
  cloud_lab_folder = data.vault_generic_secret.projects.data["cloud_lab"]
  user             = data.vault_generic_secret.projects.data["user"]
}

resource "google_project" "projects" {
  name                = "projects"
  project_id          = "projects-${local.project_id}"
  org_id              = local.org_id
  billing_account     = local.billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "projects-bucket" {
  name          = "tf-state-${resource.google_project.projects.project_id}"
  location      = "us-central1"
  project       = resource.google_project.projects.project_id
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_service_account" "sa-projects" {
  account_id   = "sa-projects"
  project      = resource.google_project.projects.project_id
  display_name = "Projects Service Account"
}

resource "google_project_iam_binding" "projects-viewer" {
  project = resource.google_project.projects.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "projects-owner" {
  project = resource.google_project.projects.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
