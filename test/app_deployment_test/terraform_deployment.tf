provider "kubernetes" {}

# Tell Terraform to use the S3 bucket for state information and the dynamoDB for state locking
terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/test/deployments.tfstate"
 }
}

resource "kubernetes_deployment" "simple-twitter" {
  metadata {
    name = "scalable-simple-twitter"
    labels = {
      App = "scalable-simple-twitter"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "scalable-simple-twitter"
      }
    }
    template {
      metadata {
        labels = {
          App = "scalable-simple-twitter"
        }
      }
      spec {
        container {
          #image = "nginx:1.7.8"
          image = "auth0blog/kubernetes-tutorial"
          name  = "auth0blog-simpletwitter-container"

          port {
            container_port = 3000
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
    }

    type = "LoadBalancer"
  }
}



output "lb_ip" {
  value = kubernetes_service.nginx.load_balancer_ingress[0].hostname
}
