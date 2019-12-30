
# This is the required configmap for the EKS cluster to let the EC2 workers join.
# After runnign "terraform apply", store this output to a file with
# „terraform output config_map_aws_auth > config_map_aws_auth.yaml" and run „kubectl apply -f config_map_aws_auth.yaml“
# afterwards to apply to the cluster
locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.demo-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}
