terraform {
  backend "gcs" {
    bucket  = "playground-s-11-b6dc4bf4_tfstate"
    prefix  = "terraform/state"
  }
}
