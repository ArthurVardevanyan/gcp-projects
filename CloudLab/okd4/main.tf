terraform {
  backend "gcs" {}

}


provider "vault" {}

provider "google" {}
provider "google-beta" {}

data "vault_generic_secret" "gke-cluster" {
  path = "secret/gcp/org/av/projects"
}

locals {
  project_id = data.vault_generic_secret.gke-cluster.data["project_id"]
  apis = [
    "compute.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
  ]
}



resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  project            = "okd4-${local.project_id}"
  service            = each.value
  disable_on_destroy = true
}
