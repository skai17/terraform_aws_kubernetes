##################################################
##          EKS Control Plane
###################################################

# create the EKS with the prepared roles, security group and subnets
resource "aws_eks_cluster" "eks" {
  name            = local.cluster-name
  role_arn        = aws_iam_role.control-plane.arn


 vpc_config {
    security_group_ids = [aws_security_group.eks-security-group.id]
    subnet_ids         = aws_subnet.application[*].id
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-control-plane-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-control-plane-AmazonEKSServicePolicy,
  ]
}


##################################################
##          Worker Node setup
###################################################


resource "aws_eks_node_group" "node_group_1"{
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${local.cluster-name}_node-group-1"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.application[*].id
  instance_types  = local.ng1_worker_instance_types

  scaling_config {
    desired_size = local.ng1_desired_size
    max_size     = local.ng1_max_size
    min_size     = local.ng1_min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}