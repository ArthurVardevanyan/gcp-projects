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
    subnetwork = "projects/network-${local.project_id}/regions/us-central1/subnetworks/gke-compute"
    access_config {}
  }

  metadata_startup_script = file("${path.module}/scripts/compute-startup.sh")

  service_account {
    email  = resource.google_service_account.sa-compute.email
    scopes = ["cloud-platform"]
  }
}
