
provider "aws" {
  assume_role {
  role_arn = "arn:aws:iam::422213079007:role/CFW-SANDBOX-ADMINS-ROLE"
}
  profile = "Sreejith"
  region  = "us-east-1"
}


resource "aws_instance" "app_server" {
  ami           = "ami-0b0af3577fe5e3532"
  instance_type = "t2.micro"
  security_groups = aws_default_security_group.default.*.id
  key_name = "Sreejith_Ec2"
  subnet_id = aws_default_subnet.default_az1.id
  tags = {
    Name = var.instance_name
  }
}


resource "aws_lb" "network_lb" {
  name               = "nlb-us-east-1b"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_instance.app_server.*.subnet_id
  enable_deletion_protection = false
    tags = {
    Environment = "Testing"
  }
}

resource "aws_lb_listener" "listener"{
load_balancer_arn = aws_lb.network_lb.arn
port = "80"
protocol = "TCP"
default_action {
  type = "forward"
  target_group_arn = aws_lb_target_group.targrp.arn
}

}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_default_vpc.default.id

  tags = {
    Name = "main"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1b"

  tags = {
    Name = "Default subnet for us-east-1b"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_target_group" "targrp" {
name     = "tf-example-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "test"{
target_group_arn = aws_lb_target_group.targrp.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}