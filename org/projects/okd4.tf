resource "google_project" "okd4" {
  name       = "okd4"
  project_id = "okd4-${local.project_id}"
  #org_id     = local.org_id
  folder_id           = local.cloud_lab_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "okd4-tf-bucket" {
  name          = "tf-state-${resource.google_project.okd4.name}-${local.bucket_id}"
  location      = "us-central1"
  project       = resource.google_project.okd4.project_id
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "okd4-viewer" {
  project = resource.google_project.okd4.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "okd4-owner" {
  project = resource.google_project.okd4.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
