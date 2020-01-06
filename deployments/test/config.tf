##################################################
##          Config for environment
###################################################
variable "stage" {
  default = "test" # <-- To be changed for new environment (e.g. test, int, prod) !
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
 key = "remote-state/test/deployments.tfstate" # <-- Change for new environment (e.g. ../test/.., ../int/.., ../prod/..) !
 }
}
