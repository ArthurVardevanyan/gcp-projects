resource "google_bigquery_dataset" "gke_usage_metering" {
  dataset_id    = "gke_usage_metering"
  friendly_name = "GKE Usage Metering"
  description   = "GKE Usage Metering"
  project       = "gke-cluster-${local.project_id}"
  location      = "US"
}

resource "google_service_account" "sa-gke-standard" {
  account_id   = "gke-standard"
  display_name = "GKE Standard Service Account"
  project      = "gke-cluster-${local.project_id}"

}

resource "google_project_iam_member" "gke-standard-node" {
  for_each = toset(local.node_roles)

  project = "gke-cluster-${local.project_id}"
  role    = each.value
  member  = "serviceAccount:${resource.google_service_account.sa-gke-standard.email}"
}

# resource "google_container_cluster" "gke-standard" {
#   provider = google-beta
#   project  = "gke-cluster-${local.project_id}"

#   name       = "gke-standard"
#   location   = "us-central1"
#   network    = "projects/network-${local.project_id}/global/networks/vpc-network"
#   subnetwork = "projects/network-${local.project_id}/regions/us-central1/subnetworks/gke-standard"

#   ip_allocation_policy {
#     cluster_secondary_range_name  = "gke-standard-pod"
#     services_secondary_range_name = "gke-standard-svc"
#   }


#   release_channel { channel = "RAPID" }

#   remove_default_node_pool = true
#   initial_node_count       = 1

#   workload_identity_config {
#     workload_pool = "gke-cluster-${local.project_id}.svc.id.goog"
#   }

#   logging_config {
#     enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
#   }

#   monitoring_config {
#     enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
#     managed_prometheus {
#       enabled = false
#     }
#   }

#   resource_usage_export_config {
#     enable_network_egress_metering       = false
#     enable_resource_consumption_metering = true
#     bigquery_destination {
#       dataset_id = "gke_usage_metering"
#     }
#   }

#   depends_on = [
#     google_project_service.container,
#     google_bigquery_dataset.gke_usage_metering
#   ]
# }

# resource "google_container_node_pool" "micro" {
#   name              = "micro"
#   location          = "us-central1"
#   project           = "gke-cluster-${local.project_id}"
#   cluster           = google_container_cluster.gke-standard.name
#   max_pods_per_node = 16

#   autoscaling {
#     min_node_count = 0
#     max_node_count = 7
#   }

#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }

#   node_config {
#     machine_type = "e2-micro"

#     disk_size_gb = 10


#     gcfs_config {
#       enabled = true
#     }

#     service_account = resource.google_service_account.sa-gke-standard.email
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform",
#       "https://www.googleapis.com/auth/devstorage.read_only",
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#       "https://www.googleapis.com/auth/service.management.readonly",
#       "https://www.googleapis.com/auth/servicecontrol",
#       "https://www.googleapis.com/auth/trace.append",
#     ]
#   }
# }
