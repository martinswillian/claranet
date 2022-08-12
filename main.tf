locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

module "network" {
  source = "./modules/network"

  region               = "${var.region}"
  environment          = "${var.environment}"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  availability_zones   = "${local.availability_zones}"
}

module "ec2" {
  source      = "./modules/ec2"
  depends_on  = [module.network]

  environment             = "${var.environment}"
  instance_type           = "${var.instance_type}"
  instance_bastion_count  = "${var.instance_bastion_count}"
  instance_http_count     = "${var.instance_http_count}"
  vpc_id                  = "${module.network.vpc_id}"
  cidr_block              = "${module.network.cidr_block}"
  subnet_id_private       = "${module.network.private_subnets_id}"
  subnet_id_public        = "${module.network.public_subnets_id}"
  subnets_alb             = "${module.network.public_subnets_id}"
}
