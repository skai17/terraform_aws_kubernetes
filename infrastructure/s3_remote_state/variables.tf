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