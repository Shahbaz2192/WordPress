provider "google" {
    credentials = file(var.gcp_credentials)
    project = var.gcp_project_id
    region = var.gcp_region
}

provider "kubernetes" {
  host                   = "https://35.227.159.12"
}
