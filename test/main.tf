# Configure the AWS Provider
provider "aws" {
  region  = var.default_zone
}


terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/test/"
 }
}
