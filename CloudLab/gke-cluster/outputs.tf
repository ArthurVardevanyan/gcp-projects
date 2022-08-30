output "logging_sa" {
  value       = resource.google_logging_project_sink.gke-autopilot.writer_identity
  description = "GKE Autopilot SA Writer Identity"
}
