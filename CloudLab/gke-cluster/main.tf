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
  # tenant      = data.vault_generic_secret.gke-cluster.data["tenant_cloudbuild"]
  # tenant_user = data.vault_generic_secret.gke-cluster.data["tenant_user"]
  node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}


resource "google_project_service" "container" {
  project            = "gke-cluster-${local.project_id}"
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gkehub" {
  project            = "gke-cluster-${local.project_id}"
  service            = "gkehub.googleapis.com"
  disable_on_destroy = false
}

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


resource "google_monitoring_monitored_project" "primary" {
  metrics_scope = "locations/global/metricsScopes/gke-tenant-${local.project_id}"
  name          = "locations/global/metricsScopes/gke-tenant-${local.project_id}/projects/gke-cluster-${local.project_id}"
}

resource "google_logging_project_sink" "gke-autopilot" {
  name    = "gke-autopilot"
  project = "gke-cluster-${local.project_id}"

  description = "Log to gke-tenants Project"
  destination = "logging.googleapis.com/projects/gke-tenant-${local.project_id}/locations/global/buckets/_Default"

  filter = <<EOH
          (resource.type = k8s_container) OR (resource.type= k8s_cluster)

          EOH

  unique_writer_identity = true
}
