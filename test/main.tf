##################################################
#
#          Basic Config
#
##################################################

# Configure the AWS Provider
provider "aws" {
  region  = var.default_zone
}

# Tell Terraform to use the S3 bucket for state information and the dynamoDB for state locking
terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/test/terraform.tfstate"
 }
}

##################################################
#
#          Network
#
##################################################

# Create the VPC
# the 2 DNS configs are required if worker node to cluster communication should be performed private within the VPC
 resource "aws_vpc" "demo" {
   cidr_block = "10.0.0.0/16"
   enable_dns_hostnames = true
   enable_dns_support = true
   tags = {
     "Name"                                      = "terraform-eks-demo-node"
     "kubernetes.io/cluster/${var.cluster-name}" = "shared"
   }
 }

 # This provides the availability zones of the current zone (e.g. eu-central-1a and eu-central-1b)
 data "aws_availability_zones" "available" {
 }

# Create <count> subnets within the available regions
# In this setup we just use one public subnet
resource "aws_subnet" "demo" {
   count = 2

   availability_zone = data.aws_availability_zones.available.names[count.index]
   cidr_block        = "10.0.${count.index}.0/24"
   vpc_id            = aws_vpc.demo.id

   tags = {
     "Name"                                      = "terraform-eks-demo-node"
     "kubernetes.io/cluster/${var.cluster-name}" = "shared"
   }
 }

# The internet gateway for access to VPC
 resource "aws_internet_gateway" "demo" {
   vpc_id = aws_vpc.demo.id

   tags = {
     Name = "terraform-eks-demo"
   }
 }

# Routing table for our VPC
 resource "aws_route_table" "demo" {
   vpc_id = aws_vpc.demo.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.demo.id
   }
 }

# Routing for the subnets
 resource "aws_route_table_association" "demo" {
   count = 2

   subnet_id      = aws_subnet.demo[count.index].id
   route_table_id = aws_route_table.demo.id
 }

##################################################
#
#          Security - Roles and policies
#
##################################################

 
 # Create the IAM role for the control plane of the cluster / EKS
resource "aws_iam_role" "demo-cluster" {
  name = "terraform-eks-demo-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# give the 2 necessary policies to the cluster IAM role
resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.demo-cluster.name
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.demo-cluster.name
}


# create the IAM role for the worker nodes
resource "aws_iam_role" "demo-node" {
  name = "terraform-eks-demo-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

# Add the required policies to the node IAM role
resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo-node.name
}

# this is needed for the aws_launch_configuration later
resource "aws_iam_instance_profile" "node" {
  name = "terraform-eks-node"
  role = aws_iam_role.demo-node.name
}


##################################################
#
#          Security - Security Groups
#
##################################################

# create a security group for the cluster / control plane
resource "aws_security_group" "demo-cluster" {
  name        = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP.
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = ["95.91.217.39/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 443
  type              = "ingress"
}


# the security group for the nodes
resource "aws_security_group" "demo-node" {
  name        = "terraform-eks-demo-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "terraform-eks-demo-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

# The following blocks allow necessary communication between the nodes and the cluster Security Groups
resource "aws_security_group_rule" "demo-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "demo-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-cluster.id
  to_port                  = 65535
  type                     = "ingress"
 }


 resource "aws_security_group_rule" "demo-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-cluster.id
  to_port                  = 443
  type                     = "ingress"
}

 resource "aws_security_group_rule" "demo-node-ingress-master-https" {
  description              = "Allow cluster control to receive communication from the worker Kubelets"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.demo-cluster.id
  source_security_group_id = aws_security_group.demo-node.id
  to_port                  = 443
  type                     = "ingress"
}

# For testing for security rule issues, I opened everything with the following 2 blocks. Should not be needed.
/*resource "aws_security_group_rule" "all_open_1" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.demo-cluster.id
  source_security_group_id = aws_security_group.demo-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "all_open_2" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.demo-node.id
  source_security_group_id = aws_security_group.demo-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}*/

##################################################
#
#          EKS Control Plane
#
##################################################

# create the EKS with the prepared roles, security group and subnets
resource "aws_eks_cluster" "demo" {
  name            = var.cluster-name
  role_arn        = aws_iam_role.demo-cluster.arn


 vpc_config {
    security_group_ids = [aws_security_group.demo-cluster.id]
    subnet_ids         = aws_subnet.demo.*.id
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy,
  ]
}


##################################################
#
#          Worker Node setup
#
##################################################


# find the most recent image for EKS worker nodes
data "aws_ami" "eks-worker" {
   filter {
     name   = "name"
     values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
   }

   most_recent = true
   owners      = ["602401143452"] # Amazon EKS AMI Account ID
 }

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We implement a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster. demo.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA

}

# Create the launch config for the autoscaling group
resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "t2.micro"
  name_prefix                 = "terraform-eks-demo"
  security_groups  = [aws_security_group.demo-node.id]
  user_data_base64 = base64encode(local.demo-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

# create the autoscaling group
resource "aws_autoscaling_group" "demo" {
  desired_capacity     = 3
  launch_configuration = aws_launch_configuration.demo.id
  max_size             = 3
  min_size             = 1
  name                 = "terraform-eks-demo"
  vpc_zone_identifier = aws_subnet.demo[*].id

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}



