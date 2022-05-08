module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.gcp_project_id
  name                       = var.gke_cluster_name
  region                     = var.gcp_region
  regional                   = false
  zones                      = var.gcp_zones
  network                    = var.gke_network
  subnetwork                 = var.gke_subnetwork
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false

  node_pools = [
    {
      name                      = var.gke_default_nodepool_name
      machine_type              = "e2-medium"
      min_count                 = 1
      max_count                 = 3
      local_ssd_count           = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      service_account           = var.gke_service_account
      preemptible               = true
      initial_node_count        = 3
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

resource "gke_default_nodepool_name" "mysql" {
  name = "wordpress-mysql"
  type = "pd-ssd"
  zone = "us-west1-a"
  size = 10
}

resource "kubernetes_persistent_volume" "mysql" {
  metadata {
    name = "mysql-pv"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = google_container_node_pool.mysql.name
        fs_type = "ext4"
      }
    }
  }
}

resource "gke_default_nodepool_name" "wordpress" {
  name = "wordpress-frontend"
  type = "pd-ssd"
  zone = "us-west1-a"
  size = 1
}

resource "kubernetes_persistent_volume" "wordpress" {
  metadata {
    name = "wordpress-pv"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = google_container_node_pool.wordpress.name
        fs_type = "ext4"
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "wordpress-mysql"
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    labels = {
      app = "wordpress"
    }
  }
  spec {
    port {
      port        = 3306
      target_port = 3306
    }
    selector = {
      app  = "wordpress"
      tier = kubernetes_replication_controller.mysql.spec[0].selector.tier
    }
    cluster_ip = "None"
  }
}

resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name = "mysql-pv-claim"
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    labels = {
      app = "wordpress"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.mysql.metadata[0].name
  }
}

resource "kubernetes_secret" "mysql" {
  
  metadata {
    name = "mysql-pass"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_replication_controller" "mysql" {
  metadata {
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    name = "wordpress-mysql"
    labels = {
      app = "wordpress"
    }
  }
  spec {
     selector = {
         app = "wordpress"
         tier = "mysql"    
    }
    template {
       metadata {
         labels = {
           app = "wordpress"
           tier = "mysql"
        }
      }
        spec {
         container {
            image = "mysql:5.6"
            name = "mysql"
            env {
              name = "MYSQL_ROOT_PASSWORD"
              value_from {
                  secret_key_ref {
                     name = "mysql-pass"
                     key = "password"
                  }
                }
              }
            
              port {
                container_port = 3306
                name = "mysql"
              }
            
              volume_mount {
                name = "mysql-persistent-storage"
                mount_path = "/var/lib/mysql"
              }
            
          }
        
        volume {
          
            name = "mysql-persistent-storage"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
            }
          }
        
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    port {
      port        = 80
      target_port = 80
    }
    selector = {
      app  = "wordpress"
      tier = kubernetes_replication_controller.wordpress.spec[0].selector.tier
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_persistent_volume_claim" "wordpress" {
  metadata {
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    name = "wp-pv-claim"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.wordpress.metadata[0].name
  }
}

resource "kubernetes_replication_controller" "wordpress" {
  metadata {
    cluster = var.gke_cluster_name
    node_pools = var.gke_default_nodepool_name
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }
  spec {
     selector = {
         app = "wordpress"
         tier = "frontend"    
    }
    template {
       metadata {
         labels = {
           app = "wordpress"
           tier = "frontend"
        }
      }
        spec {
         container {
            image = "wordpress:4.8-apache"
            name = "wordpress"
            env {
              name = "WORDPRESS_DB_HOST"
              value = "wordpress-mysql"
            }
            env {
              name = "WORDPRESS_DB_PASSWORD"
              value_from {
               secret_key_ref {
                name = kubernetes_secret.mysql.metadata[0].name
                key  = "password"
            }
          }
        }
            
              port {
                container_port = 80
                name = "wordpress"
              }
            
              volume_mount {
                name = "wordpress-persistent-storage"
                mount_path = "/var/www/html"
              }
            
          }
        
        volume {
            name = "wordpress-persistent-storage"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.wordpress.metadata[0].name
            }
          }
        
      }
    }
  }
}
