//AWS
region      = "us-east-1"
environment = "galp" //also used for name

//VPC
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"] //List of Public subnet cidr range
private_subnets_cidr = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"] //List of private subnet cidr range

//EC2
instance_type = "t2.micro"
instance_http_count = "3"
instance_bastion_count = "1"
cidr_block = ""
vpc_id = ""
