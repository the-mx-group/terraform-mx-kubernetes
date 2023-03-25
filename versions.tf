terraform {
  required_version = ">= 1"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 2.2" # needed for response_body
    }
  }
}
