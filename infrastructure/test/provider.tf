# Configure the Providers
provider "aws" {
  region  = local.region
  version = "~> 2.0"
}
# http and null are required for the nginx LB creation
provider "http" {
  version = "~> 1.1"
}
provider "null" {
  version = "~> 2.1"
}








