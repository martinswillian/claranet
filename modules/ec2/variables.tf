variable "environment" {}

variable "vpc_id" {}

variable "cidr_block" {}

variable "subnet_id_private" {}

variable "subnet_id_public" {}

variable "subnets_alb" {}

variable "instance_type" {}

variable "instance_http_count" {
  default = "1"
}

variable "instance_bastion_count" {
  default = "1"
}
