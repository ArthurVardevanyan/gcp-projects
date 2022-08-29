
###################
### Project IAM ###
###################

resource "google_project_iam_custom_role" "pubsub" {
  role_id = "pubsub.viwer"
  title   = "PubSub Viewer"
  project = "gke-tenant-${local.project_id}"

  permissions = [
    "serviceusage.services.list",
  ]
}

resource "google_project_iam_binding" "pubsub" {
  role    = resource.google_project_iam_custom_role.pubsub.id
  project = "gke-tenant-${local.project_id}"

  members = [
    #"serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
    "user:${local.tenant_user}",
  ]
}

################
### Instance ###
################

resource "google_pubsub_topic" "example" {
  name    = "example-topic"
  project = "gke-tenant-${local.project_id}"
}

resource "google_pubsub_subscription" "example" {
  name    = "example-subscription"
  topic   = google_pubsub_topic.example.name
  project = "gke-tenant-${local.project_id}"

  message_retention_duration = "86400s"
  ack_deadline_seconds       = 120
}



resource "google_pubsub_subscription_iam_binding" "subscriber" {
  subscription = google_pubsub_subscription.example.name
  project      = "gke-tenant-${local.project_id}"

  role = "roles/pubsub.subscriber"
  members = [
    #"serviceAccount:${local.tenant}@cloudbuild.gserviceaccount.com",
  ]
}


resource "google_pubsub_subscription_iam_binding" "viewer" {
  subscription = google_pubsub_subscription.example.name
  project      = "gke-tenant-${local.project_id}"

  role = "roles/pubsub.viewer"
  members = [
    "user:${local.tenant_user}",
  ]
}

resource "google_pubsub_topic_iam_binding" "viewer" {
  topic   = google_pubsub_topic.example.name
  project = "gke-tenant-${local.project_id}"

  role = "roles/pubsub.viewer"
  members = [
    "user:${local.tenant_user}",
  ]
}
