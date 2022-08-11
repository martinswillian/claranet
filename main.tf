/*resource "random_id" "random_id_prefix" {
  byte_length = 2
}*/

locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

module "GALP" {
  source = "./modules/GALP"

  region               = "${var.region}"
  environment          = "${var.environment}"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  availability_zones   = "${local.availability_zones}"

  instance_type        = "${var.instance_type}"
}
