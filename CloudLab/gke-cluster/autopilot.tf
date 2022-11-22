
resource "google_service_account" "sa-gke-autopilot" {
  account_id   = "gke-autopilot"
  display_name = "GKE Autopilot Service Account"
  project      = "gke-cluster-${local.project_id}"

}


resource "google_project_iam_member" "gke-autopilot-node" {
  for_each = toset(local.node_roles)

  project = "gke-cluster-${local.project_id}"
  role    = each.value
  member  = "serviceAccount:${resource.google_service_account.sa-gke-autopilot.email}"
}

# resource "google_container_cluster" "gke-autopilot" {
#   provider = google-beta
#   project  = "gke-cluster-${local.project_id}"

#   name             = "gke-autopilot"
#   location         = "us-central1"
#   network          = "projects/network-${local.project_id}/global/networks/vpc-network"
#   subnetwork       = "projects/network-${local.project_id}/regions/us-central1/subnetworks/gke-autopilot"
#   enable_autopilot = true

#   ip_allocation_policy {
#     cluster_secondary_range_name  = "gke-autopilot-pod"
#     services_secondary_range_name = "gke-autopilot-svc"
#   }

#   logging_config {
#     enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
#   }

#   monitoring_config {
#     enable_components = ["SYSTEM_COMPONENTS"]
#     managed_prometheus {
#       enabled = false
#     }
#   }

#   master_authorized_networks_config {
#     cidr_blocks {
#       cidr_block   = "10.0.0.0/8"
#       display_name = "10.0.0.0/8"
#     }
#     cidr_blocks {
#       cidr_block   = "100.64.0.0/10"
#       display_name = "100.64.0.0/10"
#     }
#   }

#   private_cluster_config {
#     enable_private_nodes    = true
#     enable_private_endpoint = true
#     master_ipv4_cidr_block  = "10.0.0.96/28"
#     master_global_access_config { enabled = true }
#   }

#   release_channel { channel = "RAPID" }

#   node_config {
#     # Ignored, tries to use Default Compute Engine Service Account
#     service_account = resource.google_service_account.sa-gke-autopilot.email
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#   }
#   depends_on = [
#     google_project_service.container
#   ]
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
