terraform {
  backend "gcs" {}
}

provider "google" {}

provider "vault" {}

data "vault_generic_secret" "projects" {
  path = "secret/gcp/org/av/projects"
}

locals {
  project_id = data.vault_generic_secret.projects.data["project_id"]
  org_id     = data.vault_generic_secret.projects.data["org_id"]
  user       = data.vault_generic_secret.projects.data["user"]
}


resource "google_organization_iam_binding" "roles-viewer" {
  org_id = local.org_id
  role   = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_organization_iam_binding" "organization-viewer" {
  org_id = local.org_id
  role   = "roles/resourcemanager.organizationViewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_organization_iam_binding" "billing-viewer" {
  org_id = local.org_id
  role   = "roles/billing.viewer"

  members = [
    "user:${local.user}",
  ]
}
