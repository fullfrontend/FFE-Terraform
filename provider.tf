terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.69.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }

    minikube = {
      source  = "scott-the-programmer/minikube"
      version = ">= 0.6.0"
    }
  }
}


provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes  = {
    config_path = local.kubeconfig_path
  }
}

# Minikube provider (used only when APP_ENV=dev)
provider "minikube" {
  # no specific config; uses local minikube context
}
