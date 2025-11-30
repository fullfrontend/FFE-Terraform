resource "minikube_cluster" "local" {
  provider           = minikube
  driver             = "docker"
}
