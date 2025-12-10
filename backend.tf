terraform {
  backend "gcs" {
    bucket  = "playground-s-11-749adc35_tfstate"
    prefix  = "terraform/state"
  }
}
