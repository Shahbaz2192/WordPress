

resource "kubernetes_service" "mysql" {
  metadata {
    name = "wordpress-mysql"
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
  }
}

resource "kubernetes_replication_controller" "mysql" {
  metadata {
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
                     name = "mysql-pass-7fk245f76g"
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
  }
}

resource "kubernetes_replication_controller" "wordpress" {
  metadata {
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
                name = "mysql-pass-7fk245f76g"
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
