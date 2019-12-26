# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "eu-central-1"
}

resource "aws_s3_bucket" "b" {
  bucket = "kais-first-s3-test-bucket"
  acl    = "private"

}
