resource "google_project" "gke-cluster" {
  name       = "gke-cluster"
  project_id = "gke-cluster-${local.project_id}"
  #org_id     = local.org_id
  folder_id           = local.cloud_lab_folder
  billing_account     = local.org_billing_account
  auto_create_network = false
}


resource "google_storage_bucket" "gke-cluster-tf-bucket" {
  name          = "tf-state-${resource.google_project.gke-cluster.name}-${local.bucket_id}"
  location      = "us-central1"
  project       = resource.google_project.gke-cluster.project_id
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_project_iam_binding" "gke-cluster-viewer" {
  project = resource.google_project.gke-cluster.project_id
  role    = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_project_iam_member" "gke-cluster-owner" {
  project = resource.google_project.gke-cluster.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${resource.google_service_account.sa-projects.email}"
}


resource "google_project_iam_binding" "gke-cluster-host-service-agent-user" {
  project = resource.google_project.network.project_id
  role    = "roles/container.hostServiceAgentUser"

  members = [
    "serviceAccount:${resource.google_project.gke-cluster.number}@cloudservices.gserviceaccount.com",
    "serviceAccount:service-${resource.google_project.gke-cluster.number}@container-engine-robot.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "gke-cluster-compute-subnetworks-use" {
  project = resource.google_project.network.project_id
  role    = "roles/compute.networkUser"

  members = [
    "serviceAccount:${resource.google_project.gke-cluster.number}@cloudservices.gserviceaccount.com",
    "serviceAccount:service-${resource.google_project.gke-cluster.number}@container-engine-robot.iam.gserviceaccount.com"
  ]
}
