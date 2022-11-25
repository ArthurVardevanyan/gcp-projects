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


resource "google_folder" "cloud-lab" {
  display_name = "CloudLab"
  parent       = "organizations/${local.org_id}"
}

resource "google_folder" "sandbox" {
  display_name = "Sandbox"
  parent       = "organizations/${local.org_id}"
}

resource "google_folder" "homelab" {
  display_name = "HomeLab"
  parent       = "organizations/${local.org_id}"
}

resource "google_project_service" "bigquery" {
  project            = "org-${local.project_id}"
  service            = "bigquery.googleapis.com"
  disable_on_destroy = true
}
resource "google_project_service" "bigquerydatatransfer" {
  project            = "org-${local.project_id}"
  service            = "bigquerydatatransfer.googleapis.com"
  disable_on_destroy = true
  depends_on = [
    google_project_service.bigquery
  ]
}
resource "google_bigquery_dataset" "billing_standard" {
  dataset_id    = "billing_standard"
  friendly_name = "Billing Standard"
  description   = "Billing Standard"
  project       = "org-${local.project_id}"
  location      = "US"

  depends_on = [
    google_project_service.bigquery,
    google_project_service.bigquerydatatransfer
  ]
}

resource "google_bigquery_dataset" "billing_detailed" {
  dataset_id    = "billing_detailed"
  friendly_name = "Billing Detailed"
  description   = "Billing Detailed"
  project       = "org-${local.project_id}"
  location      = "US"

  depends_on = [
    google_project_service.bigquery,
    google_project_service.bigquerydatatransfer
  ]
}

resource "google_bigquery_dataset" "billing_pricing" {
  dataset_id    = "billing_pricing"
  friendly_name = "Billing Pricing"
  description   = "Billing Pricing"
  project       = "org-${local.project_id}"
  location      = "US"

  depends_on = [
    google_project_service.bigquery,
    google_project_service.bigquerydatatransfer
  ]
}

resource "google_bigquery_dataset" "billboard_dataset" {
  dataset_id    = "billboard_dataset"
  friendly_name = "BillBoard Dataset"
  description   = "BillBoard Dataset"
  project       = "org-${local.project_id}"
  location      = "US"

  depends_on = [
    google_project_service.bigquery,
    google_project_service.bigquerydatatransfer
  ]
}
