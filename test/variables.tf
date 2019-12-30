variable "cluster-name" {
  default = "eks-cluster-test"
  type    = string
}

variable "default_zone" {
    type = string
    default = "eu-central-1"
}

variable "remote_state_s3" {
    type = string
    default = "remote-state-s3"
}

variable "remote_state_dynamo" {
    type = string
    default = "remote-state-dynamo"
}

variable "remote_state_path" {
    type = string
    default = "remote-state/test/"
}