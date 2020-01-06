##################################################
##          Config for environment
###################################################
variable "stage" {
  default = "int" # <-- To be changed for new environment (e.g. test, int, prod) !
  type    = string
}

# Tell Terraform to use the S3 bucket for state information and the dynamoDB for state locking
# Change state file (key) for different environment!
terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/int/terraform.tfstate" # <-- Change for new environment (e.g. ../test/.., ../int/.., ../prod/..) !
 }
}




##################################################
##          General config
###################################################

locals {
  # network
  region = "eu-central-1"
  subnet_count = 2
  # eks
  cluster-name = "${var.stage}-eks-cluster"
  ng1_worker_instance_types = ["t2.micro"]
  ng1_desired_size = 4
  ng1_max_size     = 8
  ng1_min_size     = 2
}