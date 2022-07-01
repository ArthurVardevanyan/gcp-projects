terraform {
  backend "gcs" {}
}

provider "vault" {}

data "vault_generic_secret" "homeassistant" {
  path = "secret/homelab/homeassistant"
}

provider "google" {
  project = data.vault_generic_secret.homeassistant.data["project_id"]
  region  = "us-central1"
}

resource "google_pubsub_subscription" "nest" {
  name  = "HomeAssistant"
  topic = "projects/sdm-prod/topics/${data.vault_generic_secret.homeassistant.data["topic"]}"

  message_retention_duration = "600s"
  retain_acked_messages      = false
  enable_message_ordering    = false
  ack_deadline_seconds       = 10
  expiration_policy {
    ttl = "2678400s"
  }
}
