##################################################
##          configure kubectl for the new cluster
###################################################

resource "null_resource" "kubectl_config" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${local.cluster-name}"
    # Add "--profile=${var.aws_profile}" to previous command if required

  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_node_group.node_group_1
  ]
}


##################################################
##          Establish nginx-ingress prerequisites
###################################################

locals {
  nginx_ingress_mandatory_yaml_url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml"
}

data "http" "nginx_ingress_mandatory" {
  url = local.nginx_ingress_mandatory_yaml_url
}

resource "null_resource" "nginx_ingress_mandatory" {
  triggers = {
    manifest_sha1 = sha1(data.http.nginx_ingress_mandatory.body)
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local.nginx_ingress_mandatory_yaml_url}"
  }

  depends_on = [
    null_resource.kubectl_config
  ]
}

##################################################
##          Establish nginx-ingress network load balancer for aws
###################################################

locals {
  nginx_ingress_nlb_aws_yaml_url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/service-nlb.yaml"
}

data "http" "nginx_ingress_nlb_aws" {
  url = local.nginx_ingress_mandatory_yaml_url
}

resource "null_resource" "nginx_ingress_nlb_aws" {
  triggers = {
    manifest_sha1 = sha1(data.http.nginx_ingress_nlb_aws.body)
  }

  // This creates a NLB in AWS
  provisioner "local-exec" {
    command = "kubectl apply -f ${local.nginx_ingress_nlb_aws_yaml_url}"
  }

  // Required for terraform destroy, because the LB in AWS must be deleted to finish it
  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -f ${local.nginx_ingress_nlb_aws_yaml_url}"
  }

  depends_on = [
    null_resource.nginx_ingress_mandatory
  ]
}

##################################################
##          Establish nginx-ingress L4 load balancer for aws
###################################################

//locals {
//  nginx_ingress_elb_aws_yaml_url1 = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/service-l4.yaml"
//  nginx_ingress_elb_aws_yaml_url2 = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/patch-configmap-l4.yaml"
//}

//data "http" "nginx_ingress_elb1_aws" {
//  url = local.nginx_ingress_elb_aws_yaml_url1
//}
//data "http" "nginx_ingress_elb2_aws" {
//  url = local.nginx_ingress_elb_aws_yaml_url2
//}
//
//resource "null_resource" "nginx_ingress_elb1_aws" {
//  triggers = {
//    manifest_sha1 = sha1(data.http.nginx_ingress_elb1_aws.body)
//  }
//
//  // This creates a NLB in AWS
//  provisioner "local-exec" {
//    command = "kubectl apply -f ${local.nginx_ingress_elb_aws_yaml_url1}"
//  }
//
//  // Required for terraform destroy, because the LB in AWS must be deleted to finish it
//  provisioner "local-exec" {
//    when = destroy
//    command = "kubectl delete -f ${local.nginx_ingress_elb_aws_yaml_url1}"
//  }
//}
//
//
//resource "null_resource" "nginx_ingress_elb2_aws" {
//
//  triggers = {
//    manifest_sha1 = sha1(data.http.nginx_ingress_elb2_aws.body)
//  }
//
//  // This creates a NLB in AWS
//  provisioner "local-exec" {
//    command = "kubectl apply -f ${local.nginx_ingress_elb_aws_yaml_url2}"
//  }
//
//  // Required for terraform destroy, because the LB in AWS must be deleted to finish it
//  provisioner "local-exec" {
//    when = destroy
//    command = "kubectl delete -f ${local.nginx_ingress_elb_aws_yaml_url2}"
//  }
//
//
//  depends_on = [
//    null_resource.nginx_ingress_mandatory
//  ]
//}

