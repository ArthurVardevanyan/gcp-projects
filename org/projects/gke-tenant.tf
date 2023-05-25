resource "google_project" "gke-tenant" {
  name       = "gke-tenant"
  project_id = "gke-tenant-${local.project_id}"
  #org_id     = local.org_id
  folder_id           = local.cloud_lab_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "gke-tenant-tf-bucket" {
  name          = "tf-state-${resource.google_project.gke-tenant.name}-${local.bucket_id}"
  location      = "us-central1"
  project       = resource.google_project.gke-tenant.project_id
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "gke-tenant-viewer" {
  project = resource.google_project.gke-tenant.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "gke-tenant-owner" {
  project = resource.google_project.gke-tenant.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
