terraform {
  backend "gcs" {
    bucket = "udemy-dev-terraform-state-cicd"
    prefix = "terraform/state"
  }
}