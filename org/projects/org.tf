resource "google_project" "org" {
  name                = "organization"
  project_id          = "org-${local.project_id}"
  org_id              = local.org_id
  billing_account     = local.billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "org-bucket" {
  name          = "tf-state-${resource.google_project.org.project_id}"
  location      = "us-central1"
  project       = resource.google_project.org.project_id
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "org-viewer" {
  project = resource.google_project.org.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "org-owner" {
  project = resource.google_project.org.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
