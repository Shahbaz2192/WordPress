provider "google" {
  project     = "My-Assignment-Project"
  region      = var.region[count.index]
}

resource "google_container_cluster" "primary" {
  name               = "My-Assignment-Project-gke"
  project = "My-Assignment-Project"
  location           = var.region[count.index]
  initial_node_count = 3
}
