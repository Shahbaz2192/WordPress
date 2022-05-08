variable "gcp_credentials" {
    type = string
    description = "location of service account for gcp"
  
}

variable "gcp_project_id" {
    type = string
    description = "gcp project id"
  
}

variable "gcp_region" {
    type = string
    description = "gcp region"
  
}

variable "gke_cluster_name" {
    type = string
    description = "gke cluster name"
  
}

variable "gcp_zones" {
    type = list(string)
    description = "list of zones"
  
}

variable "gke_network" {
    type = string
    description = "VPC of GKE"
  
}

variable "gke_subnetwork" {
    type = string
    description = "subnet of GKE"
  
}

variable "gke_default_nodepool_name" {
    type = string
    description = "name of the gke nodepool"
  
}

variable "gke_service_account" {
    type = string
    description = "gke service account"
  
}

variable "mysql_password" {
}