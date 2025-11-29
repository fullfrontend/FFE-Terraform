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
  }
}


provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "Bubus-Mac"
}
