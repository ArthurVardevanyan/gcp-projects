terraform {
  backend "gcs" {}
}

provider "vault" {}

data "vault_generic_secret" "av" {
  path = "secret/gcp/project/av"
}

provider "google" {
  project = data.vault_generic_secret.av.data["project_id"]
  region  = "us-central1"
}

resource "google_service_account" "sa-gke-autopilot" {
  account_id   = "gke-autopilot"
  display_name = "GKE Autopilot Service Account"
}

resource "google_container_cluster" "gke-autopilot" {
  provider = google-beta

  name             = "gke-autopilot"
  location         = "us-central1"
  network          = "projects/${data.vault_generic_secret.av.data["project_id"]}/global/networks/default"
  subnetwork       = "projects/${data.vault_generic_secret.av.data["project_id"]}/regions/us-central1/subnetworks/default"
  enable_autopilot = true
  release_channel { channel = "RAPID" }
  ip_allocation_policy {}
  node_config {
    service_account = "gke-autopilot@${data.vault_generic_secret.av.data["project_id"]}.iam.gserviceaccount.com" # This Doesn't Work
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
