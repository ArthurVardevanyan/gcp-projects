resource "google_project_service" "artifactregistry" {
  project            = "gke-tenant-${local.project_id}"
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# resource "google_project_service" "containerscanning" {
#   project            = "gke-tenant-${local.project_id}"
#   service            = "containerscanning.googleapis.com"
#   disable_on_destroy = true
# }

resource "google_artifact_registry_repository" "containers" {
  location      = "us-central1"
  repository_id = "containers"
  format        = "DOCKER"
  project       = "gke-tenant-${local.project_id}"

  depends_on = [
    google_project_service.artifactregistry
  ]
}

resource "google_project_iam_binding" "artifactregistry_reader" {
  project = "gke-tenant-${local.project_id}"
  role    = "roles/artifactregistry.reader"


  members = [
    "serviceAccount:gke-autopilot@gke-cluster-${local.project_id}.iam.gserviceaccount.com",
    "serviceAccount:gke-standard@gke-cluster-${local.project_id}.iam.gserviceaccount.com"
  ]
}
