data "vault_generic_secret" "projects_homelab" {
  path = "secret/gcp/org/av/folders/homelab"
}

locals {
  homelab_folder = data.vault_generic_secret.projects_homelab.data["homelab_folder"]
}

resource "google_project" "homelab" {
  name       = "homelab"
  project_id = "homelab-${local.project_id}"
  #org_id     = local.org_id
  folder_id           = local.homelab_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "homelab-tf-bucket" {
  name          = "tf-state-${resource.google_project.homelab.name}-${local.bucket_id}"
  location      = "us-central1"
  project       = resource.google_project.homelab.project_id
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "homelab-viewer" {
  project = resource.google_project.homelab.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "homelab-owner" {
  project = resource.google_project.homelab.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
