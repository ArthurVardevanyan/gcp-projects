resource "google_organization_iam_binding" "roles-viewer" {
  org_id = local.org_id
  role   = "roles/viewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_organization_iam_binding" "organization-viewer" {
  org_id = local.org_id
  role   = "roles/resourcemanager.organizationViewer"

  members = [
    "user:${local.user}",
  ]
}

resource "google_organization_iam_binding" "billing-viewer" {
  org_id = local.org_id
  role   = "roles/billing.viewer"

  members = [
    "user:${local.user}",
  ]
}
