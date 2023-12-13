data "vault_generic_secret" "projects_project_0" {
  path = "secret/gcp/org/av/folders/projects"

}

locals {
  project_0_id        = data.vault_generic_secret.projects_project_0.data["project_0_id"]
  project_0_folder    = data.vault_generic_secret.projects_project_0.data["project_folder"]
  project_0_bucket_id = data.vault_generic_secret.projects_project_0.data["project_0_bucket_id"]
  project_0_name      = data.vault_generic_secret.projects_project_0.data["project_0_name"]

}

resource "google_project" "project_0-0" {
  name       = local.project_0_name
  project_id = "${local.project_0_name}-${local.project_0_id}"
  #org_id     = local.org_id
  folder_id           = local.project_0_folder
  billing_account     = local.org_billing_account
  auto_create_network = true
}

resource "google_project_iam_member" "project_0-0" {
  project = resource.google_project.project_0-0.project_id
  role    = "roles/viewer"

  member = "user:${local.user}"
}

resource "google_project_iam_member" "project_0-0-owner" {
  project = resource.google_project.project_0-0.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}

resource "google_storage_bucket" "project_0-0-tf-bucket" {
  name          = "tf-state-${local.project_0_name}-${local.project_0_bucket_id}"
  location      = "us-central1"
  project       = resource.google_project.project_0-0.project_id
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}
