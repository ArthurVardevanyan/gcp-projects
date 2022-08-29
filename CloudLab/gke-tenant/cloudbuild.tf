
resource "google_project_service" "cloudbuild" {
  project            = "gke-tenant-${local.project_id}"
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloudbuild_trigger" "manual-trigger" {
  name    = "manual-build"
  project = "gke-tenant-${local.project_id}"

  source_to_build {
    uri       = local.repo
    ref       = "refs/heads/production"
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = "projects/GKE-Tenant/cloudbuild.yaml"
    uri       = local.repo
    revision  = "refs/heads/production"
    repo_type = "GITHUB"
  }

  substitutions = {
    _PROJECT = "gke-tenant-${local.project_id}"
  }

  depends_on = [
    google_project_service.cloudbuild
  ]
}
