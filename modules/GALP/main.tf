/*===VPC===*/

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

/*===Subnets===*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]

  tags = {
    Name        = "nat"
    Environment = "${var.environment}"
  }
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
  }
}

/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

/*===VPC's Default Security Group===*/
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags = {
    Environment = "${var.environment}"
  }
}


/*== EC2 ==*/

/* SG Public*/
resource "aws_security_group" "sg_public" {
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-public"
  }
}

/* SG Private */
resource "aws_security_group" "sg_private" {
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-private"
  }
}

/* SG ALB*/
resource "aws_security_group" "sg_alb" {
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb"
  }
}

/*Private KEY*/
resource "tls_private_key" "pem" {
  algorithm     = "RSA"
  rsa_bits      = 4096
}

resource "aws_key_pair" "pem" {
  key_name      = "${var.environment}"
  public_key    = tls_private_key.pem.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.pem.private_key_pem}" > ${var.environment}.pem
    EOT
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "ec2_private" {
  #count                       = "${length(var.private_subnets_cidr)}"
  count                       = var.instance_http_count
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  vpc_security_group_ids      = [aws_security_group.sg_private.id]
  key_name                    = aws_key_pair.pem.key_name

}

resource "aws_instance" "ec2_public" {
  #count                       = "${length(var.public_subnets_cidr)}"
  count                       = var.instance_bastion_count
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  vpc_security_group_ids      = [aws_security_group.sg_public.id]
  key_name                    = aws_key_pair.pem.key_name

}

/*===ALB===*/

/* Target Group */
resource "aws_alb_target_group" "alb_target_group" {
  name                = "${var.environment}"
  port                = 80
  protocol            = "HTTP"
  target_type         = "instance"
  vpc_id              = aws_vpc.vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 10
    matcher = "200"
  }
}

/* Target Group Attach Instance */
resource "aws_alb_target_group_attachment" "tgattachment" {
  count            = length(aws_instance.ec2_private.*.id)
  target_group_arn = aws_alb_target_group.alb_target_group.arn
  target_id        = element(aws_instance.ec2_private.*.id, count.index)
}

/*ALB*/
resource "aws_alb" "loadbalancer" {
  name                = "${var.environment}"
  load_balancer_type  = "application"
  internal            = false
  security_groups    = [aws_security_group.sg_alb.id, ]
  subnets            = aws_subnet.public_subnet.*.id
}

/*Listner*/
resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.loadbalancer.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.alb_target_group]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }
}
