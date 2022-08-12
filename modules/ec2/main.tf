/*== EC2 ==*/

/* SG Public*/
resource "aws_security_group" "sg_public" {
  name        = "${var.environment}-public"
  vpc_id      = "${var.vpc_id}"

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
    Name        = "${var.environment}-public"
    Environment = "${var.environment}"
  }
}

/* SG Private */
resource "aws_security_group" "sg_private" {
  name        = "${var.environment}-private"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["${var.cidr_block}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-private"
    Environment = "${var.environment}"
  }
}

/* SG ALB*/
resource "aws_security_group" "sg_alb" {
  name        = "${var.environment}-alb"
  vpc_id      = "${var.vpc_id}"

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
    Name        = "${var.environment}-alb"
    Environment = "${var.environment}"
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
  subnet_id                   = flatten("${var.subnet_id_private}")[count.index]
  vpc_security_group_ids      = [aws_security_group.sg_private.id]
  key_name                    = aws_key_pair.pem.key_name

  tags = {
    Name        = "${var.environment}-http-${count.index}"
    Environment = "${var.environment}"
  }

}

resource "aws_instance" "ec2_public" {
  #count                       = "${length(var.public_subnets_cidr)}"
  count                       = var.instance_bastion_count
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "${var.instance_type}"
  subnet_id                   = flatten("${var.subnet_id_public}")[count.index]
  vpc_security_group_ids      = [aws_security_group.sg_public.id]
  key_name                    = aws_key_pair.pem.key_name

  tags = {
    Name        = "${var.environment}-bastion-${count.index}"
    Environment = "${var.environment}"
  }

}

/*===ALB===*/

/* Target Group */
resource "aws_alb_target_group" "alb_target_group" {
  name                = "${var.environment}"
  port                = 80
  protocol            = "HTTP"
  target_type         = "instance"
  vpc_id              = "${var.vpc_id}"

  health_check {
    path = "/"
    port = "traffic-port"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 10
    matcher = "200"
  }

  tags = {
    Name        = "${var.environment}-tg"
    Environment = "${var.environment}"
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
  security_groups     = [aws_security_group.sg_alb.id, ]
  subnets             = flatten("${var.subnets_alb}")

  tags = {
    Name        = "${var.environment}-alb"
    Environment = "${var.environment}"
  }
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

  tags = {
    Name        = "${var.environment}-listener"
    Environment = "${var.environment}"
  }
}
