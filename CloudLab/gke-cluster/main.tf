terraform {
  backend "gcs" {}
}

provider "vault" {}

provider "google" {}

data "vault_generic_secret" "gke-cluster" {
  path = "secret/gcp/org/av/projects"
}

locals {
  project_id = data.vault_generic_secret.gke-cluster.data["project_id"]
  # tenant      = data.vault_generic_secret.gke-cluster.data["tenant_cloudbuild"]
  # tenant_user = data.vault_generic_secret.gke-cluster.data["tenant_user"]
}


resource "google_project_service" "container" {
  project            = "gke-cluster-${local.project_id}"
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "sa-gke-autopilot" {
  account_id   = "gke-autopilot"
  display_name = "GKE Autopilot Service Account"
  project      = "gke-cluster-${local.project_id}"

}

resource "google_container_cluster" "gke-autopilot" {
  provider = google-beta
  project  = "gke-cluster-${local.project_id}"

  name             = "gke-autopilot"
  location         = "us-central1"
  network          = "projects/network-${local.project_id}/global/networks/vpc-network"
  subnetwork       = "projects/network-${local.project_id}/regions/us-central1/subnetworks/gke-autopilot"
  enable_autopilot = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-autopilot-pod"
    services_secondary_range_name = "gke-autopilot-svc"
  }


  master_authorized_networks_config {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "10.9.0.0/28"
    master_global_access_config { enabled = true }
  }

  release_channel { channel = "RAPID" }

  node_config {
    # Ignored, tries to use Default Compute Engine Service Account
    service_account = resource.google_service_account.sa-gke-autopilot.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
  depends_on = [
    google_project_service.container
  ]
}

# resource "google_project_service" "gkehub" {
#   project            = "gke-cluster-${local.project_id}"
#   service            = "gkehub.googleapis.com"
#   disable_on_destroy = false
# }
# resource "google_gke_hub_membership" "gke-autopilot" {
#   membership_id = google_container_cluster.gke-autopilot.name
#   project       = "gke-cluster-${local.project_id}"
#   endpoint {
#     gke_cluster {
#       resource_link = "//container.googleapis.com/${google_container_cluster.gke-autopilot.id}"
#     }
#   }
#   depends_on = [
#     google_project_service.gkehub
#   ]
# }

# resource "google_project_iam_custom_role" "gke_tenant" {
#   project = "gke-cluster-${local.project_id}"
#   role_id = "gke.tenant"
#   title   = "GKE Tenant"
#   permissions = [
#     "container.apiServices.get",
#     "container.apiServices.list",
#     "container.clusters.get",
#     "container.clusters.getCredentials",
#     "container.clusters.list",
#     "monitoring.timeSeries.list",
#     # Cloud Resources
#     "resourcemanager.projects.get",
#   ]
# }

# resource "google_project_iam_binding" "gke_tenant" {
#   project = "gke-cluster-${local.project_id}"
#   role    = resource.google_project_iam_custom_role.gke_tenant.id

#   members = [
#     "serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
#     "user:${local.tenant_user}",
#   ]
# }


# resource "google_monitoring_monitored_project" "primary" {
#   metrics_scope = "locations/global/metricsScopes/${local.tenant}"
#   name          = "locations/global/metricsScopes/${local.tenant}/projects/${local.project_id}"
# }

resource "google_service_account" "sa-compute" {
  project      = "gke-cluster-${local.project_id}"
  account_id   = "sa-compute"
  display_name = "Compute Engine Service Account"

}

resource "google_project_iam_binding" "container_admin" {
  project = "gke-cluster-${local.project_id}"
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${resource.google_service_account.sa-compute.email}"
  ]
}
resource "google_compute_instance" "gce" {
  name         = "gce-micro"
  project      = "gke-cluster-${local.project_id}"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  tags = ["iap"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    subnetwork = "projects/network-${local.project_id}/regions/us-central1/subnetworks/gke-autopilot"
    access_config {}
  }

  service_account {
    email  = resource.google_service_account.sa-compute.email
    scopes = ["cloud-platform"]
  }
}
