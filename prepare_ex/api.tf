# Active l'API Cloud Resource Manager
resource "google_project_service" "resource_manager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Active l'API Service Usage
resource "google_project_service" "service_usage_api" {
  project = var.project_id
  service = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

# L'API Cloud Run DOIT dépendre des deux APIs précédentes
resource "google_project_service" "cloud_run_api" {
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
  depends_on = [
    google_project_service.resource_manager_api,
    google_project_service.service_usage_api
  ]
}