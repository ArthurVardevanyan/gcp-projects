terraform {
  backend "gcs" {}
}

provider "google" {}

provider "vault" {}

data "vault_generic_secret" "projects" {
  path = "secret/gcp/org/av/projects"
}

data "vault_generic_secret" "homelab" {
  path = "secret/homelab/domain"
}

locals {
  project_id = data.vault_generic_secret.projects.data["project_id"]
  homelab_ip = data.vault_generic_secret.homelab.data["ip"]
}


resource "google_compute_network" "vpc_network" {
  project                 = "network-${local.project_id}"
  name                    = "vpc-network"
  auto_create_subnetworks = false
}

resource "google_project_service" "cloudresourcemanager" {
  project            = "network-${local.project_id}"
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = "network-${local.project_id}"
}

resource "google_compute_shared_vpc_service_project" "gke-cluster" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = "gke-cluster-${local.project_id}"
}

resource "google_compute_shared_vpc_service_project" "okd4" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = "okd4-${local.project_id}"
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

resource "google_compute_firewall" "allow-all-ingress" {
  allow {
    protocol = "all"
  }
  description = "Allows All Ingress"
  direction   = "INGRESS"
  disabled    = false
  name        = "allow-all-ingress"
  network     = google_compute_network.vpc_network.self_link
  priority    = 1000
  project     = "network-${local.project_id}"
  source_ranges = [
    "10.0.0.0/8", "100.64.0.0/10"
  ]
}
resource "google_compute_firewall" "allow-all-egress" {
  allow {
    protocol = "all"
  }
  description = "Allows All Egress"
  direction   = "EGRESS"
  disabled    = false
  name        = "allow-all-egress"
  network     = google_compute_network.vpc_network.self_link
  priority    = 1000
  project     = "network-${local.project_id}"
  destination_ranges = [
    "10.0.0.0/8", "100.64.0.0/10"
  ]
}

resource "google_compute_firewall" "allow-gosmee" {
  allow {
    ports    = [3333]
    protocol = "TCP"
  }
  description = "Allows Gosmee"
  direction   = "INGRESS"
  disabled    = false
  name        = "allow-gosmee"
  network     = google_compute_network.vpc_network.self_link
  priority    = 1000
  project     = "network-${local.project_id}"
  source_ranges = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "143.55.64.0/20",
    "${local.homelab_ip}"
  ]
}

# 10.0.0.0/8
# https://www.davidc.net/sites/default/subnets/subnets.html?network=10.0.0.0&mask=8&division=43.ffff7a00000
# 100.64.0.0/10
# https://www.davidc.net/sites/default/subnets/subnets.html?network=100.64.0.0&mask=10&division=33.ff7a32000

resource "google_compute_subnetwork" "gke-compute" {
  name    = "gke-compute"
  project = "network-${local.project_id}"

  ip_cidr_range = "10.0.0.0/27"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

}

resource "google_compute_subnetwork" "gke-autopilot" {
  name    = "gke-autopilot"
  project = "network-${local.project_id}"

  ip_cidr_range = "10.0.0.32/27"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "gke-autopilot-pod"
    ip_cidr_range = "100.64.0.0/21"
  }
  secondary_ip_range {
    range_name    = "gke-autopilot-svc"
    ip_cidr_range = "100.64.24.0/24"
  }
}


resource "google_compute_subnetwork" "gke-standard" {
  name    = "gke-standard"
  project = "network-${local.project_id}"

  ip_cidr_range = "10.0.0.64/27"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
  secondary_ip_range {
    range_name    = "gke-standard-pod"
    ip_cidr_range = "100.64.8.0/21"
  }
  secondary_ip_range {
    range_name    = "gke-standard-svc"
    ip_cidr_range = "100.64.25.0/24"
  }
}

module "gcp-arthurvardevanyan-com" {
  source                             = "terraform-google-modules/cloud-dns/google"
  project_id                         = "network-${local.project_id}"
  type                               = "public"
  name                               = "gcp-arthurvardevanyan-com"
  domain                             = "gcp.arthurvardevanyan.com."
  private_visibility_config_networks = [google_compute_network.vpc_network.self_link]

  enable_logging = true

  dnssec_config = {
    state = "on"
  }
}
