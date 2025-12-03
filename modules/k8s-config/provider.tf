terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }
  }
}

/*
    Providers read kubeconfig_path:
    - prod writes ${path.root}/.kube/config
    - dev uses ~/.kube/config (ex: docker-desktop)
*/
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}
