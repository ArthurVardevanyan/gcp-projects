data "vault_generic_secret" "projects_sandbox" {
  path = "secret/gcp/org/av/folders/sandbox"

}

locals {
  sandbox_id     = data.vault_generic_secret.projects_sandbox.data["sandbox_id"]
  sandbox_folder = data.vault_generic_secret.projects_sandbox.data["sandbox_folder"]
  user-0         = data.vault_generic_secret.projects_sandbox.data["user-0"]
}

resource "google_project" "sandbox-0" {
  name       = "sandbox-0"
  project_id = "sandbox-0-${local.sandbox_id}"
  #org_id     = local.org_id
  folder_id           = local.sandbox_folder
  billing_account     = local.org_billing_account
  auto_create_network = true
}

resource "google_project_iam_member" "sandbox-0" {
  project = resource.google_project.sandbox-0.project_id
  role    = "roles/viewer"

  member = "user:${local.user}"
}

resource "google_project_iam_member" "sandbox-0-owner" {
  project = resource.google_project.sandbox-0.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}

resource "google_project_iam_member" "sandbox-0-editor" {
  project = resource.google_project.sandbox-0.project_id
  role    = "roles/editor"
  member  = "user:${local.user-0}"
}
