resource "google_project_service" "services-ic" {
  for_each           = toset(var.service_list)
  project            = var.project_id_ic
  service            = each.key
  disable_on_destroy = false
}

resource "google_project_service" "services-trusted" {
  for_each           = toset(var.service_list)
  project            = var.project_id_trusted
  service            = each.key
  disable_on_destroy = false
}
