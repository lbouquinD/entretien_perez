terraform {
  backend "gcs" {
    bucket  = "playground-s-11-87bb59e8_tfstate"
    prefix  = "terraform/state"
  }
}
