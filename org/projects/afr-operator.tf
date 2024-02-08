resource "google_project" "afr-operator" {
  name       = "afr-operator"
  project_id = "afr-operator-5560235161"
  #org_id     = local.org_id
  folder_id           = local.project_0_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "afr-operator-tf-bucket" {
  name          = "tf-state-${resource.google_project.afr-operator.name}-5560235161"
  location      = "us-central1"
  project       = resource.google_project.afr-operator.project_id
  force_destroy = true

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "afr-operator-viewer" {
  project = resource.google_project.afr-operator.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "afr-operator-owner" {
  project = resource.google_project.afr-operator.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}
