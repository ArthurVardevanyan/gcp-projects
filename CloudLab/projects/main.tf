terraform {
  backend "gcs" {}
}

provider "google" {}

provider "vault" {}

data "vault_generic_secret" "projects" {
  path = "secret/gcp/projects"
}

locals {
  project_id      = data.vault_generic_secret.projects.data["project_id"]
  billing_account = data.vault_generic_secret.projects.data["billing_account"]
  user            = data.vault_generic_secret.projects.data["user"]
}

resource "google_project" "projects" {
  name                = "projects"
  project_id          = "projects-${local.project_id}"
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
