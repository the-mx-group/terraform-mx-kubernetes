terraform {
  required_version = ">= 1"

  required_providers {
    kubectl = { # remove this provider eventually
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
}
