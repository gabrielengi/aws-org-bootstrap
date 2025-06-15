# backend-dev/versions.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible AWS provider version
    }
  }
  # No backend block here, as this project will initially use local state
  # to create the remote backend.
}