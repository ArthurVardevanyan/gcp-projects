terraform {
  backend "gcs" {}
}

provider "vault" {}

data "vault_generic_secret" "av" {
  path = "secret/gcp/project/av"
}

locals {
  project_id = data.vault_generic_secret.av.data["project_id"]
}
provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_service_account" "sa-gke-autopilot" {
  account_id   = "gke-autopilot"
  display_name = "GKE Autopilot Service Account"
}

resource "google_container_cluster" "gke-autopilot" {
  provider = google-beta
  project  = local.project_id

  name             = "gke-autopilot"
  location         = "us-central1"
  network          = "default"
  subnetwork       = "default"
  enable_autopilot = true
  release_channel { channel = "RAPID" }
  ip_allocation_policy {}
  node_config {
    # Ignored, tries to use Default Compute Engine Service Account
    service_account = resource.google_service_account.sa-gke-autopilot.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_service_account" "sa-compute" {
  account_id   = "sa-compute"
  display_name = "Compute Engine Service Account"
}
resource "google_compute_instance" "default" {
  name         = "gce-micro"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
  }

  service_account {
    email  = resource.google_service_account.sa-compute.email
    scopes = ["cloud-platform"]
  }
}
