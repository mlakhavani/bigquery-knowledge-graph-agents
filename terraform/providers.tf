terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
}

provider "google-beta" {
}

provider "google" {
  # The provider credentials will be used to create the project and resources.
  # We do not set a default project here because the project is created by Terraform.
}
