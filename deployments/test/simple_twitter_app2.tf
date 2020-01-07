locals{
  simple_twitter_app2_name = "${var.stage}-simple-twitter2"
}


resource "kubernetes_deployment" "simple-twitter2" {
  metadata {
    name = local.simple_twitter_app2_name
    labels = {
      App = local.simple_twitter_app2_name
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = local.simple_twitter_app2_name
      }
    }
    template {
      metadata {
        labels = {
          App = local.simple_twitter_app2_name
        }
      }
      spec {
        container {
          #image = "nginxdemos/hello"
          image = "auth0blog/kubernetes-tutorial"
          name  = local.simple_twitter_app2_name

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


resource "kubernetes_service" "simple-twitter2" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      App = kubernetes_deployment.simple-twitter2.spec.0.template.0.metadata[0].labels.App
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
  value = kubernetes_service.simple-twitter2.load_balancer_ingress[0].hostname
}