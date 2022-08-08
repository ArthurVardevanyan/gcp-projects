terraform {
  backend "gcs" {}
}

provider "vault" {}

data "vault_generic_secret" "gke-cluster" {
  path = "secret/gcp/project/gke-cluster"
}

locals {
  project_id  = data.vault_generic_secret.gke-cluster.data["project_id"]
  tenant      = data.vault_generic_secret.gke-cluster.data["tenant_cloudbuild"]
  tenant_user = data.vault_generic_secret.gke-cluster.data["tenant_user"]
}

provider "google" {
  project = local.project_id
  region  = "us-central1"
  zone    = "us-central1-a"
}


resource "google_project_service" "api" {
  project            = local.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
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

  master_authorized_networks_config {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
  }

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

resource "google_project_iam_custom_role" "gke_tenant" {
  role_id = "gke.tenant"
  title   = "GKE Tenant"
  permissions = [
    "container.apiServices.get",
    "container.apiServices.list",
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusters.list",
    "monitoring.timeSeries.list",
    # Cloud Resources
    "resourcemanager.projects.get",
  ]
}

resource "google_project_iam_binding" "gke_tenant" {
  project = local.project_id
  role    = resource.google_project_iam_custom_role.gke_tenant.id

  members = [
    "serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
    "user:${local.tenant_user}",
  ]
}

resource "google_monitoring_monitored_project" "primary" {
  metrics_scope = "locations/global/metricsScopes/${local.tenant}"
  name          = "locations/global/metricsScopes/${local.tenant}/projects/${local.project_id}"
}

# resource "google_service_account" "sa-compute" {
#   account_id   = "sa-compute"
#   display_name = "Compute Engine Service Account"
# }
# resource "google_compute_instance" "default" {
#   name         = "gce-micro"
#   machine_type = "e2-micro"
#   zone         = "us-central1-a"

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }
#   network_interface {
#     network = "default"
#   }

#   service_account {
#     email  = resource.google_service_account.sa-compute.email
#     scopes = ["cloud-platform"]
#   }
# }

###################
### Project IAM ###
###################

resource "google_project_iam_custom_role" "pubsub" {
  role_id = "pubsub.viwer"
  title   = "PubSub Viewer"
  permissions = [
    "serviceusage.services.list",
  ]
}

resource "google_project_iam_binding" "pubsub" {
  project = local.project_id
  role    = resource.google_project_iam_custom_role.pubsub.id

  members = [
    "serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
    "user:${local.tenant_user}",
  ]
}

################
### Instance ###
################

resource "google_pubsub_topic" "example" {
  name = "example-topic"
}

resource "google_pubsub_subscription" "example" {
  name  = "example-subscription"
  topic = google_pubsub_topic.example.name

  message_retention_duration = "86400s"
  ack_deadline_seconds       = 120
}



resource "google_pubsub_subscription_iam_binding" "subscriber" {
  subscription = google_pubsub_subscription.example.name

  role = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
  ]
}


resource "google_pubsub_subscription_iam_binding" "viewer" {
  subscription = google_pubsub_subscription.example.name

  role = "roles/pubsub.viewer"
  members = [
    "user:${local.tenant_user}",
  ]
}

resource "google_pubsub_topic_iam_binding" "viewer" {
  topic = google_pubsub_topic.example.name

  role = "roles/pubsub.viewer"
  members = [
    "user:${local.tenant_user}",
  ]
}
