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
}


resource "google_compute_network" "vpc_network" {
  project                 = "network-${local.project_id}"
  name                    = "vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = "network-${local.project_id}"
}

resource "google_compute_shared_vpc_service_project" "gke-cluster" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = "gke-cluster-${local.project_id}"
}


resource "google_compute_subnetwork" "gke-autopilot" {
  name    = "gke-autopilot"
  project = "network-${local.project_id}"

  ip_cidr_range = "10.10.0.0/28"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "gke-autopilot-pod"
    ip_cidr_range = "10.11.0.0/23"
  }
  secondary_ip_range {
    range_name    = "gke-autopilot-svc"
    ip_cidr_range = "10.12.0.0/27"
  }
}
