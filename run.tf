resource "google_cloud_run_v2_service" "daveo_cloud_run" {
  name     = "daveo-test-service"
  location = "europe-west1" 

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" 
    }
  }
  
  # Configuration pour rendre le service PUBLIC
}
