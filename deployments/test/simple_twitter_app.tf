provider "kubernetes" {}

locals{
  app_name = "${var.stage}-simple-twitter"
}


resource "kubernetes_deployment" "simple-twitter" {
  metadata {
    name = local.app_name
    labels = {
      App = local.app_name
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = local.app_name
      }
    }
    template {
      metadata {
        labels = {
          App = local.app_name
        }
      }
      spec {
        container {
          #image = "nginxdemos/hello"
          image = "auth0blog/kubernetes-tutorial"
          name  = local.app_name

          port {
            container_port = 3000
            #container_port = 80
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      App = kubernetes_deployment.simple-twitter.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 3000
      #target_port = 80
    }

    type = "LoadBalancer"
  }
}



output "lb_ip" {
  value = kubernetes_service.nginx.load_balancer_ingress[0].hostname
}
