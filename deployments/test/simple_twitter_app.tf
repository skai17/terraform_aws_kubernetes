locals{
  simple_twitter_app_name = "${var.stage}-simple-twitter"
  simple_twitter_clusterIP_service_name =  "${var.stage}-simple-twitter-clusterip"
}

resource "kubernetes_deployment" "simple-twitter" {

  metadata {
    name = local.simple_twitter_app_name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = local.simple_twitter_app_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.simple_twitter_app_name
        }
      }

      spec {
        container {
          image = "auth0blog/kubernetes-tutorial"
          name  = local.simple_twitter_app_name
          port {
            container_port = 3000
          }
        }
      }
    }
  }
    depends_on = [
    kubernetes_service.simple-twitter
  ]
}


resource "kubernetes_service" "simple-twitter" {

  metadata {
    name = local.simple_twitter_clusterIP_service_name
  }

  spec {
    selector = {
      app = local.simple_twitter_app_name
    }

    port {
      port        = 80
      protocol    = "TCP"
      target_port = 3000
    }

    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_ingress.simple-twitter
  ]
}


resource "kubernetes_ingress" "simple-twitter" {

  metadata {
    name = "${local.simple_twitter_app_name}-ingress"
  }

  spec {
    rule {
      http {
        path {
          path = "/twitter"

          backend {
            service_name = local.simple_twitter_clusterIP_service_name
            service_port = 80
          }
        }
      }
    }
  }
}