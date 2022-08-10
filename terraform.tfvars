//AWS
region      = "us-east-1"
environment = "galp"

/* module networking */
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"] //List of Public subnet cidr range
private_subnets_cidr = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"] //List of private subnet cidr range
