terraform {
  required_version = ">=0.13.0"
  required_providers {
    google = ">= 3.88, < 5.0"
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-vm:compute_instance/v9.0.0"
  }
}