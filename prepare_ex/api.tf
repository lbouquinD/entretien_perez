# Activer l'API Cloud Run Admin
resource "google_project_service" "cloud_run_api" {
  # Remplacez ceci par l'ID de votre projet si vous ne le passez pas via le provider/variable
  project = var.project_id 
  service = "run.googleapis.com"
  
  # Assure que l'API reste activée
  disable_on_destroy = false 
}
