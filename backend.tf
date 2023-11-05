terraform {
  backend "gcs" {
    bucket = "terraform-state-job-cicdproject"
    prefix = "terraform/state"
  }
}