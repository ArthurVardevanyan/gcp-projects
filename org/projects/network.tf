resource "google_project" "network" {
  name       = "network"
  project_id = "network-${local.project_id}"
  #  org_id     = local.org_id
  folder_id           = local.cloud_lab_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "network-bucket" {
  name          = "tf-state-${resource.google_project.network.project_id}"
  location      = "us-central1"
  project       = resource.google_project.network.project_id
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "network-viewer" {
  project = resource.google_project.network.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "network-owner" {
  project = resource.google_project.network.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}

resource "google_project_service" "container_api" {
  project            = resource.google_project.network.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}
