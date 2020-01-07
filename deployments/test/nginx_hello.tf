locals{
  hello_app_name = "${var.stage}-nginx-hello"
  clusterIP_service_name =  "${var.stage}-nginx-hello-clusterip"
}

resource "kubernetes_deployment" "nginx_hello" {

  metadata {
    name = local.hello_app_name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = local.hello_app_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.hello_app_name
        }
      }

      spec {
        container {
          image = "nginxdemos/hello"
          name  = local.hello_app_name
          port {
            container_port = 80
          }
        }
      }
    }
  }
    depends_on = [
    kubernetes_service.nginx_hello
  ]
}


resource "kubernetes_service" "nginx_hello" {

  metadata {
    name = local.clusterIP_service_name
  }

  spec {
    selector = {
      app = local.hello_app_name
    }

    port {
      port        = 8081
      protocol    = "TCP"
      target_port = 80
    }

    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_ingress.nginx_hello
  ]
}


resource "kubernetes_ingress" "nginx_hello" {

  metadata {
    name = "${local.hello_app_name}-ingress"
  }

  spec {
    rule {
      http {
        path {
          path = "/hello"

          backend {
            service_name = local.clusterIP_service_name
            service_port = 8081
          }
        }
      }
    }
  }
}