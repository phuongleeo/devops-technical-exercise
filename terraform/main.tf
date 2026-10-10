terraform {
  required_version = "~> 1.16.5"
  backend "local" {}

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3, < 4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.3, < 4"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "kind-w3w-local"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-w3w-local"
}
