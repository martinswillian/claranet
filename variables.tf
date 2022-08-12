#AWS
variable "region" {
}

variable "environment" {
}

#Networking
variable "vpc_cidr" {
}

variable "public_subnets_cidr" {
  type        = list
}

variable "private_subnets_cidr" {
  type        = list
}

#EC2
variable "vpc_id" {}

variable "cidr_block" {}

variable "instance_type" {}

variable "instance_http_count" {
  default = "1"
}

variable "instance_bastion_count" {
  default = "1"
}
