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

resource "google_compute_firewall" "allow-iap-traffic" {
  allow {
    ports    = [22]
    protocol = "tcp"
  }
  target_tags = ["iap"]
  description = "Allows TCP connections from IAP to any instance on the network using port 22."
  direction   = "INGRESS"
  disabled    = false
  name        = "allow-iap-traffic"
  network     = google_compute_network.vpc_network.self_link
  priority    = 1000
  project     = "network-${local.project_id}"
  source_ranges = [
    "35.235.240.0/20" // Cloud IAP's TCP netblock see https://cloud.google.com/iap/docs/using-tcp-forwarding
  ]
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


resource "google_compute_subnetwork" "gke-standard" {
  name    = "gke-standard"
  project = "network-${local.project_id}"

  ip_cidr_range = "10.13.0.0/27"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "gke-standard-pod"
    ip_cidr_range = "10.14.0.0/22"
  }
  secondary_ip_range {
    range_name    = "gke-standard-svc"
    ip_cidr_range = "10.15.0.0/27"
  }
}
